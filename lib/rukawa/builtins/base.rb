require 'rukawa/job'

module Rukawa
  module Builtins
    class Base < ::Rukawa::Job
      class << self
        def [](name = nil, **params)
          klass = Class.new(self) do
            def_parameters(params)
          end
          Object.const_set(name, klass)
        end

        def def_parameters(**params)
        end
      end
    end
  end
end
