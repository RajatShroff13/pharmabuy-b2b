/* PharmaBuy B2B - shared front-end behaviour */
(function () {
    "use strict";

    document.addEventListener("DOMContentLoaded", function () {
        // Auto-dismiss flash messages so the layout does not shift on every page.
        document.querySelectorAll(".alert-dismissible").forEach(function (alert, index) {
            window.setTimeout(function () {
                if (window.bootstrap && window.bootstrap.Alert) {
                    window.bootstrap.Alert.getOrCreateInstance(alert).close();
                }
            }, 6000 + index * 500);
        });

        // Bootstrap tooltips (opt-in with data-bs-toggle="tooltip").
        if (window.bootstrap && window.bootstrap.Tooltip) {
            document.querySelectorAll('[data-bs-toggle="tooltip"]').forEach(function (el) {
                window.bootstrap.Tooltip.getOrCreateInstance(el);
            });
        }

        // Any link/button carrying data-confirm asks before running.
        document.querySelectorAll("[data-confirm]").forEach(function (el) {
            el.addEventListener("click", function (event) {
                if (!window.confirm(el.getAttribute("data-confirm"))) {
                    event.preventDefault();
                }
            });
        });

        // Payment method cards on the checkout page.
        var paymentRadios = document.querySelectorAll('input[name="payment_mode"]');
        function paintPayment() {
            document.querySelectorAll(".payment-option").forEach(function (card) {
                card.classList.remove("is-selected");
            });
            var checked = document.querySelector('input[name="payment_mode"]:checked');
            if (checked && checked.nextElementSibling) {
                checked.nextElementSibling.classList.add("is-selected");
            }
        }
        paymentRadios.forEach(function (radio) {
            radio.addEventListener("change", paintPayment);
        });
        if (paymentRadios.length) {
            paintPayment();
        }
    });
})();
