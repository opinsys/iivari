//= require jquery
//= require jquery.offline
//= require jqs5.opinsys
//= require underscore
//= require backbone
//= require slideshow

//= require_self
//= require_tree ./models
//= require_tree ./views

window.Iivari = {
    Models: {},
    Collections: {},
    Routers: {},
    Views: {},
    init: function() {
        // no routing! only one view!
        new Iivari.Views.Conductor();
    }
};

$(document).ready(function() {
    Iivari.init();
});
