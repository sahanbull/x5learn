window.addEventListener("load", function() {    
    window.cookieconsent.initialise({
      onInitialise: function(status) 
      {
        if (this.hasConsented('required')) {
          console.log('Required cookies allowed.');
        }
    
        if (this.hasConsented('analytics')) {
          console.log('Analytical cookies allowed.');
        }
    
        if (this.hasConsented('marketing')) {
          console.log('Marketing cookies allowed.');
        }
      },
    
      onAllow: function(category) 
      {
        if (category == 'required') {
          console.log('Required cookies just allowed.');
        }
    
        if (category == 'analytics') {
          console.log('Analytical cookies just allowed.');
        }
    
        if (category == 'marketing') {
          console.log('Marketing cookies just allowed.');
        }
      },
    
      onRevoke: function(category) 
      {
        if (category == 'required') {
          console.log('Required cookies just revoked.');
        }
    
        if (category == 'analytics') {
          console.log('Analytical cookies just revoked.');
        }
    
        if (category == 'marketing') {
          console.log('Marketing cookies just revoked.');
        }
      }
    })
});