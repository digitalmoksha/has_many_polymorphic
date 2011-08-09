module RussellEdge #:nodoc:
    module HasManyPolymorphic #:nodoc:

      def self.included(base)
        base.extend(ClassMethods)
      end

      module ClassMethods
      
        ##
        #  HasManyPolymorphic
        #  This mixin adds a has many polymorphic relationship to a model and creates all the relationships needed
        #  by rails to handle it.
        #
        #  Params
        #
        #  Name - name of the relationship, there is a convention that whatever name you choose, the polymorphic
        #  table columns on your through table should match.
        #
        #  Options
        #   - through - the model that handles the through relationship
        #   - models  - models that should be included in this polymophic relationship
        #
        #
        #  One method is added for you to use
        #
        #  - {name param}
        #    - the name of your relationship is used for the method name of this method. it will return
        #    an array of the models that are related via the has_many relationships
        #
        #  There is an after_save call back that will save the relationships when they are added or removed
        #  If you want to remove a relationship the models need to be destroyed and this model reloaded.
        #
        #  Example Usage
		#  
		#  class PreferenceType < ActiveRecord::Base
		#  	has_morpheus :preferenced_records,
        #       :through => :valid_preference_types,
        #       :models => [:desktops, :organizers]
		#  end
		#  
		#  this gives you the following
		#
		#  preferenceType = PreferenceType.first
		#  preferenceType.desktops
		#  preferenceType.organizers
		#   
		#  and
		#   
		#  preferenceType.preferenced_records
		#   
		#  which is a concatentated array of the models. You also get the following
		#   
		#  desktop = Desktop.first
		#  desktop.preference_types
		#   
		#  organizer = Organizer.first
		#  organizer.preference_types
        ##

        def has_many_polymorphic(name, options = {})
          target_class_name = self.name
          instance_array_name = "#{name}_array".to_sym
          
          #declare array to related models
          attr_accessor instance_array_name
        
          #create the has_many relationship
          has_many options[:through], :dependent => :destroy

          #create the has_many relationship for each model
          options[:models].each do |model|
            has_many model, :through => options[:through], :source => model.to_s.singularize,
              :conditions => ["#{options[:through]}.#{name.to_s.singularize}_type = ?", model.to_s.classify], :dependent => :destroy
          end

          #modify the through class to add the belongs to relationships
          options[:through].to_s.classify.constantize.class_exec do
            options[:models].each do |model|
              belongs_to model.to_s.singularize.to_sym, :class_name => model.to_s.classify, :foreign_key => "#{name.to_s.singularize}_id"
            end
          end

          #I want to keep the  << and push methods of array so this helps to keep them.
          define_method name do
            #used the declared instance variable array
            records = self.send(instance_array_name.to_s)
            records = records || []
            options[:models].each do |model|
              records = records | self.send(model.to_s)
            end
            
            #set it back to the instance variable
            self.send("#{instance_array_name.to_s}=", records)
            
            records
          end

          #before we save this model make sure you save all the relationships.
          before_save do |record|
            record.send(name).each do |reln_record|
              conditions = "#{name.to_s.singularize}_id = #{reln_record.id} and #{name.to_s.singularize}_type = '#{reln_record.class.name}'"
              exisiting_record = record.send("#{options[:through]}").find(:first,
                :conditions => conditions)

              if exisiting_record.nil?
                values_hash = {}
                values_hash["#{record.class.name.underscore}_id"] = record.id
                values_hash["#{name.to_s.singularize}_type"] = reln_record.class.name
                values_hash["#{name.to_s.singularize}_id"] = reln_record.id
              
                options[:through].to_s.classify.constantize.create(values_hash)
              end
            end
          end
			
	      #include instance methods into this model
          include RussellEdge::HasManyPolymorphic::InstanceMethods

          #add the relationship to the models.
          options[:models].each do |model|           
            model.to_s.classify.constantize.class_exec do
              #build the has many polymorphic relationship via finder_sql
              has_many options[:through], :as => name.to_s.singularize
              has_many target_class_name.tableize, :through => options[:through]

              #we want to save the relantionships when the model is saved
              before_save do |record|
                record.send(target_class_name.underscore.pluralize).each do |reln_record|

                  db_result = ActiveRecord::Base.connection.select_all("SELECT count(*) as num_rows FROM #{options[:through]}
                                                    where #{name.to_s.singularize}_id = #{record.id}
                                                    and #{name.to_s.singularize}_type = '#{record.class.name}'
                                                    and #{target_class_name.underscore.singularize}_id = #{reln_record.id}")

                  #make sure that the relantionship does not already exist
                  num_rows = db_result[0]['num_rows'] unless db_result == -1
                  if num_rows.nil? || num_rows.to_i == 0
                    values_hash = {}
                    values_hash["#{reln_record.class.name.underscore}_id"] = reln_record.id
                    values_hash["#{name.to_s.singularize}_type"] = record.class.name
                    values_hash["#{name.to_s.singularize}_id"] = record.id
                    options[:through].to_s.classify.constantize.create(values_hash)
                  end
                end
              end
            end

            model.to_s.classify.constantize.class_eval do
              #check if this is using STI if so use the type attribute else use the class name
              def model_class_name
                if attributes['type']
                  attributes['type']
                else
                  self.class.to_s
                end
              end
            end
          end

        end
      end
				
      module InstanceMethods
        #clear array on reload
        def reload(*args)
          @records = []

          super args
        end

      end

    end
  end