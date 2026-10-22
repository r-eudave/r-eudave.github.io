# Rafael Ramírez Eudave — personal website

An English/Spanish personal website positioned at the interplay of heritage, risk, and digitisation. The editorial framing connects heritage values and community knowledge, vulnerability assessment, and digital evidence as mutually informing perspectives. It distinguishes physical loss from the loss of knowledge and meaning, and presents documentation as support for conservation, not a substitute for it.

**Website:** https://r-eudave.github.io/

## Structure

- `index.html`: accessible English content and authored Spanish translations.
- `styles.css`: responsive layout, reduced-motion support, and print styles.
- `script.js`: language selection through `?lang=en` or `?lang=es`, translated metadata, and footer year. English content works without JavaScript; Spanish requires JavaScript.
- `assets/`: locally hosted, resized portfolio images and favicon.
- `.nojekyll`: serves the site as plain static files on GitHub Pages.

No framework, package installation, external fonts, analytics, cookies, or build step is required. Language links preserve the current section. The site makes no third-party requests until a visitor follows an external link.

## Content and image sources

Content is adapted from the privately maintained repository `r-eudave/0_CV-and-Portfolio`, revision `d050a7560aa782d7d0b34ac3f5242a83b0f7ce1f`:

- `CV_EN.tex` and `Portfolio_EN.tex`: biography, dates, research, and professional links.
- `design.tex`: original burgundy identity colour, `#360e1d`.
- `images/project-10.jpg`, `project-16.jpg`, `project-20.jpg`, `project-22.jpg`, `project-24.jpg`, `project-25.jpg`: selected portfolio plates, resized to a maximum dimension of 1600 pixels.
- `assets/heritage-model.jpg`: cropped from the top of `images/project-10.jpg`.

Research headings on the website describe research themes; they are not presented as verbatim article titles. Follow DOI links for full bibliographic records. Publication and funding figures reflect the source CV and should be updated when it changes. Contact uses the professional email in the source; the phone number is deliberately omitted. Only selected projects are published: the full CV, full portfolio, and CORDHISK software are offered by email on request, not linked to inaccessible private repositories.

Images retain the authorship and rights of their original portfolio contributions; this repository does not grant a new licence for those works.

## Editing

Edit English content directly in `index.html` and the corresponding Spanish content in its `data-es` attribute. Use `data-es-alt` for image descriptions and `data-es-aria` for accessible labels. Only elements marked `data-translation-html` accept authored `<br>` line breaks; other translations are inserted as text. Project image links open the full selected plate; separate text links open a DOI record, a selected plate, or an email request.

## Local preview

Use any static HTTP server with this directory as its root. For example, if Ruby with WEBrick is available:

```sh
ruby -rwebrick -e 'WEBrick::HTTPServer.new(Port: 8080, BindAddress: "127.0.0.1", DocumentRoot: Dir.pwd).start'
```

Open `http://127.0.0.1:8080/` and `http://127.0.0.1:8080/?lang=es`.

## GitHub Pages

Publish from the `main` branch, `/ (root)`, in **Settings → Pages → Build and deployment → Deploy from a branch**. GitHub manages the Pages build and HTTPS. Push updates to `main` to republish.

Verify both languages, mobile layouts, image links, navigation, and contact links before publishing updates.
