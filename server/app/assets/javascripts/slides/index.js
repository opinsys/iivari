$(document).ready(function(){
    $('#previewSlides').click(function (event){
        var url = $(this).attr("href");
        window.open(url, "iivariPreview", "width=720,height=480");
        event.preventDefault();
    });

    $('#slides').sortable({
        axis: 'y',
        dropOnEmpty: false,
        handle: 'span',
        cursor: 'crosshair',
        items: 'li',
        opacity: 0.4,
        scroll: true,
        update: function(){
            $.ajax({
		type: 'post',
		data: $('#slides').sortable('serialize'),
		dataType: 'script',
		url: 'slides/sort'})
        }
    });

    $(".slide_item").mouseenter(function() {
        $(this).find('.action').fadeIn(300);
    });
    $(".slide_item").mouseleave(function() {
        $(this).find('.action').fadeOut(300);
    });
});
