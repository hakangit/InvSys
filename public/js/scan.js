var scanFields = {
    upca: /^\d{12}$/,
    imei: /^\d{15}$/,
    iccid: /^\d{20}$/,
    modelid: /^1P\w{2}\d{3}\w{2}\/\w$/,
    serial: /^S\w{12}$/,
};

function toTitleCase(str)
{
    return str.replace(/\w\S*/g, function(txt){return txt.charAt(0).toUpperCase() + txt.substr(1).toLowerCase();});
}

var scanNames = Object.keys(scanFields);
var scanElement = document.getElementById("scanFields");
var e = document.createElement("div");
e.classList.add("btn-group");
// scanElement.innerHTML="<b>foobar</b>";

scanNames.forEach(function(n){
    var v = document.createElement("button");
    var l = document.createElement("input"); //TODO: add hidden input for the form submit
    v.id = n;
    l.id = "input_" + n;
    v.classList.add("btn","btn-info");
    v.innerText = v.textContent = n.toUpperCase();
    l.classList.add("form-control");
    l.type = "hidden";
    l.name = "device["+n+"]";
    l.class = "form-group";
    e.appendChild(l);
    e.appendChild(v);
    scanElement.appendChild(e);
});

var scanData = {};

function haveAll() {
    var all = scanNames.every(function(n) {
        var v = scanData[n];
        return v && v.length>0;
    });
    var s = document.getElementById("submit").classList;
    s.add(all?"btn-success":"btn-danger");
    s.remove(!all?"btn-success":"btn-danger");
    return all;
}

function scan(field, n) {

    var code = field.value;

    function scanMatch(id, regex) {
        if (code.match(regex)) {
            var e = document.getElementById(id);
            // e.innerText = e.textContent = code;
            e.classList.remove("btn-info");
            e.classList.add("btn-success");
            var i = document.getElementById("input_"+id);
            i.value = code;
            scanData[id]=code;
        }
    }
    function arrayCopy(a){
        return Array.slice.call(a);
    }


    scanNames.forEach(function(n){
        scanMatch(n, scanFields[n]);
    });

    if (!haveAll()) field.focus();



}

console.log("Loaded Scan");

document.getElementsByName("device[0]")[0].focus();
