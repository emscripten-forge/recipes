import re
from typing import Any, Optional

from pydantic import BaseModel, ConfigDict, field_validator, model_validator


def _has_version_template(url: str) -> bool:
    return "${{version" in url.replace(" ", "") and "}}" in url


def _validate_archive_url(url: str) -> str:
    url_pattern = r"^(https://.*|http://.*)\.(tar\.gz|tar\.bz2|tar\.xz|tgz|zip)$"
    if not re.match(url_pattern, url):
        raise ValueError(
            "Source url must be a valid link (https://...) to an archive file "
            "(tar.gz, tar.bz2, tar.xz, .tgz, or .zip)"
        )
    return url


def _urls_from_entry(entry: dict) -> list[str]:
    url = entry.get("url")
    if url is None:
        return []
    if isinstance(url, list):
        return url
    return [url]


class UrlSource(BaseModel):
    """Source with URL and SHA256 (standard remote sources)."""
    url: str | list[str]
    sha256: str

    @field_validator("url")
    @classmethod
    def validate_url_format(cls, v: str | list[str]) -> str | list[str]:
        if isinstance(v, list):
            return [_validate_archive_url(url) for url in v]
        return _validate_archive_url(v)

    @field_validator("sha256")
    @classmethod
    def validate_sha256(cls, v: str) -> str:
        if not re.match(r"^[0-9a-f]{64}$", v):
            raise ValueError("source.sha256 must be a 64-character hex string")
        return v


def validate_build_number(number: int | str, context: dict | None = None) -> None:
    if isinstance(number, int):
        if number < 0:
            raise ValueError("build.number must be an integer >= 0")
        return
    if number == "${{ build_number }}":
        context_build_number = (context or {}).get("build_number")
        if not isinstance(context_build_number, int) or context_build_number < 0:
            raise ValueError("context.build_number must be an integer >= 0")
        return
    raise ValueError("build.number must be an integer >= 0 or ${{ build_number }}")


def _source_entries(source: Any) -> list[dict]:
    if source is None:
        return []
    if isinstance(source, list):
        return [entry for entry in source if isinstance(entry, dict)]
    if isinstance(source, dict):
        return [source]
    return []


def _is_path_only_entry(entry: dict) -> bool:
    return "path" in entry and "url" not in entry and "git" not in entry


def validate_source_block(source: Any) -> None:
    entries = _source_entries(source)
    if not entries:
        return

    if all(_is_path_only_entry(entry) for entry in entries):
        return

    has_primary_source = False
    url_sources: list[str] = []
    for entry in entries:
        if "git" in entry:
            has_primary_source = True
            continue
        if _is_path_only_entry(entry):
            continue
        if "url" in entry:
            UrlSource.model_validate(entry)
            url_sources.extend(_urls_from_entry(entry))
            has_primary_source = True

    if not has_primary_source:
        raise AttributeError("source must contain at least one url+sha256 or git entry")

    if url_sources and not any(_has_version_template(url) for url in url_sources):
        raise AttributeError(
            "At least one source url must contain ${{ version }} for automatic updates."
        )


def _output_name(output: dict) -> str:
    if "package" in output:
        return output["package"].get("name", "unknown")
    if "staging" in output:
        return output["staging"].get("name", "unknown")
    return "unknown"


class Build(BaseModel):
    number: int | str


class PackageSpec(BaseModel):
    name: str
    version: Optional[str] = None


class StagingSpec(BaseModel):
    name: str


class Output(BaseModel):
    model_config = ConfigDict(extra="allow")

    package: Optional[PackageSpec] = None
    staging: Optional[StagingSpec] = None
    inherit: Optional[str] = None
    tests: Optional[Any] = None
    build: Optional[Any] = None
    source: Optional[Any] = None


class About(BaseModel):
    license: str
    license_file: str | list[str]
    license_family: Optional[str] = None


class Recipe(BaseModel):
    model_config = ConfigDict(extra="allow")

    about: About
    build: Optional[Build] = None
    source: Optional[Any] = None
    tests: Optional[Any] = None
    outputs: Optional[list[Output]] = None

    @model_validator(mode="before")
    @classmethod
    def validate_recipe(cls, values: Any) -> Any:
        if not isinstance(values, dict):
            return values

        if "about" not in values:
            raise AttributeError("Recipe must have an 'about' section.")

        context = values.get("context", {})
        if not isinstance(context, dict):
            context = {}

        outputs = values.get("outputs")
        has_outputs = isinstance(outputs, list) and len(outputs) > 0
        top_build = values.get("build")
        if not isinstance(top_build, dict) or "number" not in top_build:
            raise AttributeError("Recipe must have a top-level build.number.")
        validate_build_number(top_build["number"], context)

        if has_outputs:
            for output in outputs:
                if not isinstance(output, dict):
                    continue
                output_build = output.get("build")
                if isinstance(output_build, dict) and "number" in output_build:
                    raise AttributeError("Use top-level build.number only, remove build.number from outputs.")
                if "source" in output:
                    validate_source_block(output["source"])

        if "source" in values:
            validate_source_block(values["source"])

        if values.get("tests") is None:
            if has_outputs:
                for output in outputs:
                    if not isinstance(output, dict):
                        continue
                    if "staging" in output:
                        continue
                    if "tests" not in output:
                        raise AttributeError(
                            f"Output '{_output_name(output)}' must have a 'tests' section."
                        )
            else:
                raise AttributeError("Recipe must have a 'tests' section.")

        return values
