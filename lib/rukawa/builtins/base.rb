require 'rukawa/job'

module Rukawa
  module Builtins
    class Base < ::Rukawa::Job
      class << self
        def [](**params)
          Class.new(self) do
            def_parameters(params)

            def self.name
              super || "#{superclass.name}_#{object_id}"
            end
          end
        end

        def def_parameters(**params)
        end
      end
    end
  end
end
