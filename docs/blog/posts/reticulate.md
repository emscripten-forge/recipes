```{post} 2026-10-07
:author: derthorsten
:category: python, r-lang
```


# Mixed R and Python workflows in the browser with Emscripten-Forge

## Language-agnostic package management
Programming languages like R or Python have their own package management systems, which are typically language-specific. Native extensions often came as an afterthought, by allowing the platform-specific binaries to be bundled within a package. However, this model limits reuse and shared binary dependencies across packages from different ecosystems.


This was one of the core motivations for the conda package management system, which is modeled after Linux distributions. Conda treats R, Python, and other tools as peers, allowing them to share common dependencies.
Emscripten-forge brings this model to the browser. While tools like Pyodide (Python), a pioneer in that space, and WebR (R) focus on single-language ecosystems, emscripten-forge supports both R and Python, as well as console applications, and native libraries.

## Reticulate in the browser

Today, we are thrilled to announce that the Reticulate R package is available in emscripten-forge, enabling users to call Python from R, and enabling workflows that would not be possible with language-specific ecosystems.

Including r-reticulate in your environment.yml file, as well as the required Python dependencies of your workflow, will allow you to directly invoke Python from R.

You can try it right now by clicking on the link below:


[r-reticulate on notebook.link](https://notebook.link/@DerThorsten/r-reticulate)



![Reticulate in the browser](/assets/reticulate_light.png)

### Acknowledgements:
The work by Thorsten Beier at QuantStack on the port of reticulate to WebAssembly was funded by Safran Tech.

### About the Author
Thorsten Beier is a senior software developer at QuantStack. He is the original creator of emscripten-forge, and remains a lead developer of the project today.
