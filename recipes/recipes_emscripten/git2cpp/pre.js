Module["libgit2_convert_url"] = (input_url) => {
  // Convert URL to use CORS proxy based on env vars GIT_CORS_PROXY and GIT_CORS_PROXY_TYPE.
  const url = new URL(input_url);
  const env = Module["ENV"] ?? {};
  const GIT_CORS_PROXY = env["GIT_CORS_PROXY"];
  if (GIT_CORS_PROXY) {
    const GIT_CORS_PROXY_TYPE = env["GIT_CORS_PROXY_TYPE"] ?? "prefix";
    if (GIT_CORS_PROXY_TYPE == "prefix") {
      return `${GIT_CORS_PROXY}${input_url}`;
    } else if (GIT_CORS_PROXY_TYPE == "insert") {
      let ret = `${url.protocol}//${GIT_CORS_PROXY}`;
      if (ret.at(-1) != '/') {
        ret += '/';
      }
      return `${ret}${url.host}${url.pathname}${url.search}`;
    }
    console.warn(`Invalid GIT_CORS_PROXY_TYPE of '${GIT_CORS_PROXY_TYPE}'`);
  }
  return input_url;
};
