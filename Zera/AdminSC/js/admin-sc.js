$(document).ready(function(){

    $('#name').keyup(function() {
        var title = $('#name').val();
        title = title.replace(/\W/gi, "-");
        title = title.replace(/\-\-+/gi, "-");
        title = title.toLowerCase();
        $('#url').val(title);
    });

});
