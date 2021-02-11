# frozen_string_literal: true

module ActiveRecord
  module Type
    ##
    # Attributes are looked up based on the type and the current adapter.
    # For example, attribute :foo, :string has a type :string.
    #
    # The issue is that our adapter is :postgis, but all of the
    # attributes are registered under :postgresql. This overwrite
    # just forces us to always return :postgresql.
    #
    # The caveat is that when registering spatial types, we have
    # to specify :postgesql as the adapter, not :postgis.
    #
    # ex. ActiveRecord::Type.register(:st_point, OID::Spatial, adapter: :postgresql)
    class << self
      def adapter_name_from(_model)
        :postgresql
      end

      private

      def current_adapter_name
        :postgresql
      end
    end
  end
end
