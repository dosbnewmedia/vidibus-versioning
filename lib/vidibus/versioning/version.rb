module Vidibus
  module Versioning
    class Version
      include ::Mongoid::Document
      include ::Mongoid::Timestamps
      include Vidibus::Uuid::Mongoid

      belongs_to :versioned, polymorphic: true

      field :versioned_uuid, type: String
      field :versioned_attributes, type: Hash, default: {}
      field :number, type: Integer

      index({versioned_uuid: 1, number: 1})

      validates :versioned_uuid, :versioned_attributes, :number, presence: true
      validates :number, uniqueness: {
        scope: [:versioned_id, :versioned_type]
      }

      before_validation :set_number, :set_versioned_uuid

      scope :timeline, -> { desc(:created_at) }

      def past?
        !!(created_at && created_at < Time.now)
      end

      def future?
        !!(created_at && created_at >= Time.now)
      end

      protected

      def set_number
        return if number
        previous = Version.
          where({
            versioned_id: versioned_id,
            versioned_type: versioned_type
          }).
          desc(:number).limit(1).first
        self.number = previous ? previous.number + 1 : 1
      end

      def set_versioned_uuid
        self.versioned_uuid = versioned.uuid
      end
    end
  end
end
