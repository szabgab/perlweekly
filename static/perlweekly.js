function set_local_date() {
    // Assume a date format of "2021-04-13T19:00:00+03:00";
    // Display time in localtime of the browser.

    const dates = document.getElementsByClassName("begin");
    for (let ix=0; ix < dates.length; ix++) {
        //const mydate = dates[ix].getAttribute("x-schedule");
        const mydate = dates[ix].getAttribute("datetime");
        console.log(mydate);
        const date = new Date(mydate);

        dates[ix].innerHTML = date.toLocaleDateString( [], {
            weekday: 'long',
            year: 'numeric',
            month: 'long',
            day: 'numeric',
            hour: 'numeric',
            minute: 'numeric',
            timeZoneName: 'long'
        });
    }
}

set_local_date();
