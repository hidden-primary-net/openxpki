OXI.TextView = Ember.View.extend({
<<<<<<< HEAD
   templateName: "text-view",
   content:null,
   headline:null,
   paragraphs:null,
   
   init:function(){
       Ember.debug('OXI.TextView :init ');
       this._super();
       this.headline = this.content.headline;
       this.paragraphs = this.content.paragraphs;
    }
   
=======
    templateName: "text-view",
    content:null,
    headline:null,
    paragraphs:null,

    init:function(){
        Ember.debug('OXI.TextView :init ');
        this._super();
        this.headline = this.content.headline;
        this.paragraphs = this.content.paragraphs;
    }

>>>>>>> dsiebeck/feature/webui
});