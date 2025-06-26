Fingerprint = {};

Fingerprint.Open = function () {
    $(".fingerprint-container").fadeIn(150);
    $(".fingerprint-id").html("Fingerprint ID<p>No result</p>");
};

Fingerprint.Close = function () {
    $(".fingerprint-container").fadeOut(150);
    $.post("https://esx_policejob/closeFingerprint");
};

Fingerprint.Update = function (data) {
    $(".fingerprint-id").html("Fingerprint ID<p>" + data.fingerprintId + "</p>");
};

$(document).on("click", ".take-fingerprint", function () {
    $.post("https://esx_policejob/doFingerScan");
});


document.onreadystatechange = () => {
    if (document.readyState === "complete") {
        window.addEventListener("message", function (event) {
            if (event.data.type == "fingerprintOpen") {
                Fingerprint.Open();
            } else if (event.data.type == "fingerprintClose") {
                Fingerprint.Close();
            } else if (event.data.type == "updateFingerprintId") {
                Fingerprint.Update(event.data);
            } else if (event.data.type == "startTimer") {
                StartTimer()
            } else if (event.data.type == "stopTimer") {
                StopTimer()
            }
        });
    }
};

var TimerInterval;
var seconds = 60;
var tens = 0;

const StartTimer = () =>{
    seconds = 60;
    tens = 0;
    TimerInterval = setInterval(doTimer, 10);
    document.getElementById("timer").style.display = 'block';
}

function doTimer() {
    tens--;

    if (tens < 0) {
        tens = 99;

        seconds--;

        if (seconds < 0) {
            // If needed, you can add logic here to handle when the countdown reaches zero.
            // For now, the countdown will stop at 00:00.
            seconds = 0;
            tens = 0;
            clearInterval(TimerInterval);
            document.getElementById("timer").style.display = 'none';
            $.post("https://esx_policejob/timer");
        }
    }

    var appendTens = document.getElementById("tens");
    var appendSeconds = document.getElementById("seconds");

    // Display the countdown
    appendTens.innerHTML = tens <= 9 ? "0" + tens : tens;
    appendSeconds.innerHTML = seconds <= 9 ? "0" + seconds : seconds;
}

const StopTimer = () =>{
    if (TimerInterval != null){
        clearInterval(TimerInterval);
        document.getElementById("timer").style.display = 'none';
        TimerInterval = null;
        seconds = 60;
        tens = 0;
        $.post("https://esx_policejob/timer");
    }

}


$(document).on("keydown", function () {
    switch (event.keyCode) {
        case 27: // ESC
            Fingerprint.Close();
            break;
    }
});
