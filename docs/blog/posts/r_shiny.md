```{post} 2026-10-08
:author: IsabelParedes
:category: r-lang
:image: 1
```

# Serverless Shiny Dashboards with Emscripten-Forge

```{image} ../../assets/blog_banner_r_shiny.png
:alt: Emscripten-forge and Shiny
:class: banner dark-light
```

We are excited to announce the integration of Shiny with emscripten-forge, enabling fully-static Shiny dashboards that run entirely in the browser and can be published to GitHub Pages with a single template repository.

## The Cost of Traditional Shiny Deployment

In a traditional Shiny deployment, the application runs on a server, typically backed by an R process. This means that you need to provide computing resources proportionally to the number of user sessions: every concurrent visitor requires memory and CPU on your infrastructure. If many people connect at once, say, during a course, a product launch, or a conference demo, you may need to provision expensive cloud resources, or risk degraded performance and timeouts.

Beyond raw cost, operating a Shiny server also comes with the usual operational burdens: keeping the server up to date, monitoring, scaling policies, and access control.

## WebAssembly Changes Everything

WebAssembly changes the economics of Shiny deployment entirely. With R compiled to WebAssembly, the application logic runs in the browser of each visitor: compute resources are provided by the user, and your infrastructure cost goes from $O(n)$ to $O(1)$. Serving the dashboard is no different from serving any static website, a flat cost, regardless of how many people connect.

For most basic Shiny applications, the resources available to a modern browser are more than enough. This model is a perfect fit for:

- **Education**: interactive course materials and exercises that every student can run independently, at no cost to the institution.
- **Documentation**: interactive docs and examples that are always live, with no backend to maintain.
- **Sharing quantitative results at scale**: interactive reports and results that can be shared with thousands of readers without provisioning a single server.

Today, we announce the integration of **Shiny** with **emscripten-forge**.

## Why Emscripten-Forge?

Emscripten-forge is a conda/mamba-based software distribution for the Web browser. Unlike language-specific ecosystems such as Pyodide (Python) and WebR (R), emscripten-forge is language-agnostic: Python, R, GNU Octave packages, console applications, and native libraries are all peers that can share common binary dependencies.

This matters beyond convenience. Because R and Python packages live in the same dependency graph, a static R-Shiny dashboard built with emscripten-forge can invoke Python code directly — imagine a Shiny UI backed by a Python ML model or a Python data-processing library, all in a single static page. Language-specific runtimes cannot offer this out of the box.

## How Does it Work?

Lucent is a browser runtime dedicated to running Shiny apps entirely on the client side; it boots a full R-Shiny stack inside the browser. When a Lucent site is opened, a bundled WebAssembly environment (R runtime and all required dependencies) are loaded onto a virtual filesystem. The Shiny app is initialized from within that local R session, without the need for a remote R server or any installation required by the visitor.

To Shiny, the setup still acts as an ordinary web server, but this server is virtual.  A service worker intercepts HTTP and WebSocket traffic from the app and forwards it to R running in a background worker. The app UI is displayed in an embedded iframe and matches the experience of a regular Shiny dashboard while keeping all R computations entirely on the user’s machine.

```{raw} html
:file: ../../assets/blog_r_shiny_arch.svg
```

To simplify deployments, we developed [`lucent-pack`](https://github.com/emscripten-forge/lucent-pack), a tool which turns a Shiny app and its R environment into a fully static site. Lucent-pack requires two inputs: the path to the Shiny app directory and the path to the WebAssembly environment containing all of the app dependencies. Then, it uses [`empack`](https://github.com/emscripten-forge/empack) to archive the environment and the app into tarballs. Lastly, it outputs a publishable static tree which includes the lucent runtime. This static site will automatically boot R, run the Shiny app, and connect the app UI to the browser’s R session.

## Deploying Shiny Dashboards to GitHub Pages

To make this easy to try, we provide a GitHub template repository that builds and publishes a static Shiny dashboard to GitHub Pages in a few clicks:

👉 [Try the GitHub template repository!](https://github.com/emscripten-forge/r-shiny-template)

The requirements to run the app are specified in the [environment.yaml](https://github.com/emscripten-forge/r-shiny-template/blob/main/environment.yaml) file. The template automatically creates a WebAssembly environment based on the environment file, and it uses `lucent-pack` to generate the static bundle and publish to GitHub pages.

```{image} ../../assets/r_shiny_demo.gif
:alt: SVM demo shiny app running on GitHub pages
:class: banner dark-light
```

👉 [Try the demo!](https://emscripten-forge.github.io/r-shiny-template/)

## About the Author

**Isabel Paredes** is a senior software developer at QuantStack and a lead developer of emscripten-forge, where she ported the Xeus-R Jupyter kernel to WebAssembly. She has a strong focus on the Jupyter ecosystem (a Jupyter Distinguished Contributor and member of the Jupyter Software Steering Council), and also works on improving the accessibility of JupyterLab. In the past, she has worked on the open-source robotics ecosystem.