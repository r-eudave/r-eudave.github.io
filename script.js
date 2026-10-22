"use strict";

const language = new URLSearchParams(window.location.search).get("lang") === "es" ? "es" : "en";
document.documentElement.lang = language;
document.querySelectorAll("[data-language]").forEach((link) => {
  if (link.dataset.language === language) {
    link.setAttribute("aria-current", "true");
  } else {
    link.removeAttribute("aria-current");
  }
  link.hash = window.location.hash;
});

if (language === "es") {
  document.querySelectorAll("[data-es]").forEach((element) => {
    if (element.hasAttribute("data-translation-html")) {
      // Only the authored line breaks in local translations are treated as markup.
      const lines = element.dataset.es.split("<br>");
      element.replaceChildren();
      lines.forEach((line, index) => {
        if (index > 0) element.append(document.createElement("br"));
        element.append(document.createTextNode(line));
      });
    } else {
      element.textContent = element.dataset.es;
    }
  });
  document.querySelectorAll("[data-es-alt]").forEach((image) => {
    image.alt = image.dataset.esAlt;
  });
  document.querySelectorAll("[data-es-aria]").forEach((element) => {
    element.setAttribute("aria-label", element.dataset.esAria);
  });
  document.title = "Rafael Ramírez Eudave | Patrimonio, investigación y futuros digitales";
  document.querySelector('meta[name="description"]').content =
    "Rafael Ramírez Eudave, arquitecto e investigador en patrimonio digital, memoria colectiva y riesgo sísmico. Investigador Marie Skłodowska-Curie en TU Delft.";
  document.querySelector('meta[property="og:title"]').content = document.title;
  document.querySelector('meta[property="og:description"]').content =
    document.querySelector('meta[name="description"]').content;
  document.querySelector('meta[property="og:url"]').content = "https://r-eudave.github.io/?lang=es";
  document.querySelector('meta[property="og:image:alt"]').content =
    "Reconstrucción fotogramétrica de la Igreja dos Grilos en Oporto";
  document.querySelector('link[rel="canonical"]').href = "https://r-eudave.github.io/?lang=es";
}

window.addEventListener("hashchange", () => {
  document.querySelectorAll("[data-language]").forEach((link) => {
    link.hash = window.location.hash;
  });
});
document.getElementById("year").textContent = new Date().getFullYear();
