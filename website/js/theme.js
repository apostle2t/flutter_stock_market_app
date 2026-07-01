// Applies the saved theme immediately (before the rest of the page
// renders) to avoid a flash of the wrong theme on load.
(function applyStoredTheme() {

    const saved = localStorage.getItem("aetherTheme");

    if (saved === "light") {
        document.documentElement.setAttribute("data-theme", "light");
    }

})();


function setupThemeToggle() {

    const btn = document.getElementById("themeToggleBtn");

    if (!btn) return;

    function updateIcon() {

        const isLight = document.documentElement.getAttribute("data-theme") === "light";
        btn.textContent = isLight ? "☀️" : "🌙";

    }

    updateIcon();

    btn.addEventListener("click", () => {

        const isLight = document.documentElement.getAttribute("data-theme") === "light";

        if (isLight) {
            localStorage.setItem("aetherTheme", "dark");
        } else {
            localStorage.setItem("aetherTheme", "light");
        }

        // Reload so any Chart.js canvases on this page redraw with the
        // correct text color for the new theme — Chart.js renders to
        // canvas and can't pick up CSS variable changes live.
        location.reload();

    });

}


document.addEventListener("DOMContentLoaded", setupThemeToggle);


/**
 * Returns the right Chart.js text color for the current theme.
 * Chart.js renders to canvas, so it can't read CSS variables directly —
 * callers should call this at chart-creation time (and whenever
 * re-creating a chart after a theme switch) for axis labels, legends,
 * and tick text.
 */
function getChartTextColor() {

    const isLight = document.documentElement.getAttribute("data-theme") === "light";
    return isLight ? "#0F1E42" : "#A0AEC0";

}