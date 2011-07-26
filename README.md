### HasManyPolymorphic

This mixin adds a has many polymorphic relationship to a model and creates all the relationships needed by rails to handle it.
        
### Params
- Name 
	- name of the relationship, there is a convention that whatever name you choose, the polymorphic table columns on your through table should match.
        
-Options
	- through - the model that handles the through relationship
	- models  - models that should be included in this polymophic relationship
        
        
### Added methods
        
  - {name param}
	- the name of your relationship is used for the method name of this method. it will return an array of the models that are related via the has_many relationships
        
There is an after_save call back that will save the relationships when they are added or removed. If you want to remove a relationship the models need to be destroyed and this model reloaded.
        
### Example Usage
		  
    class PreferenceType < ActiveRecord::Base
      has_many_polymorphic :preferenced_records,
        :through => :valid_preference_types,
        :models => [:desktops, :organizers]
    end
		  
this gives you the following
		
    preferenceType = PreferenceType.first
    preferenceType.desktops
    preferenceType.organizers
		   
and
		   
		  preferenceType.preferenced_records
		   
which is a concatentated array of the models. You also get the following
		   
    desktop = Desktop.first
    desktop.preference_types
		   
    organizer = Organizer.first
    organizer.preference_types