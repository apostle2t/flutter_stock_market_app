const loginForm =
    document.getElementById("loginForm");

if (loginForm) {

    loginForm.addEventListener(
        "submit",
        function(e){

            e.preventDefault();

            const email =
                document.getElementById("email").value;

            const password =
                document.getElementById("password").value;

            if(email && password){

                localStorage.setItem(
                    "loggedInUser",
                    email
                );

                alert(
                    "Login successful!"
                );

                window.location.href =
                    "index.html";
            }

        }
    );

}
