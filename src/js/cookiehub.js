window.addEventListener("load", function() {    
    window.cookieconsent.initialise({
      onInitialise: function(status) 
      {
        if (this.hasConsented('required')) {
          // x5gon Cookie Init should go here
          console.log('Required cookies allowed.');
        }
      },
    
      onAllow: function(category) 
      {
        if (category == 'required') {
          // x5gon Cookie Init should go here
          console.log('Required cookies just allowed.');
        }
      },
    
      onRevoke: function(category) 
      {
        if (category == 'required') {
          // x5gon Cookie destroy should go here
          console.log('Required cookies just revoked.');
        }
      }
    })
});