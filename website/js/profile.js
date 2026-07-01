const editProfileBtn = document.getElementById("editProfileBtn");
 
if (editProfileBtn) {
 
    editProfileBtn.addEventListener("click", function () {
 
        alert("Profile editing is not available in this demo version.");
 
    });
 
}
 
// Notification toggles just persist visually for this session;
// no backend, matches the demo-mode pattern used elsewhere on the site.
const pushToggle = document.getElementById("pushToggle");
const priceAlertsToggle = document.getElementById("priceAlertsToggle");
 
[pushToggle, priceAlertsToggle].forEach((toggle) => {
 
    if (!toggle) return;
 
    toggle.addEventListener("change", function () {
 
        console.log(`${toggle.id} set to ${toggle.checked}`);
 
    });
 
});
