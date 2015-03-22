module MySQL
  module Types
    alias SqlType = String|Time|Int32|Int64|Float64|Nil

    struct Value
      property value
      property field

      def initialize(@value, @field)
      end

      def account_for_zero
        1
      end

      def parsed
        value
      end

      def lift
        VALUE_DISPATCH.fetch(field.field_type) { Value }.new(value, field)
      end
    end

    struct Datetime < Value
      def parsed
        TimeFormat.new("%F %T").parse(value)
      end
    end

    struct Date < Value
      def parsed
        TimeFormat.new("%F").parse(value)
      end
    end

    struct Integer < Value
      def parsed
        value.to_i
      end
    end

    struct Float < Value
      def parsed
        value.to_f
      end
    end

    struct Bit < Value
      def parsed
        parsed_value = 0_i64
        value.each_char do |char|
          parsed_value *= 256
          parsed_value += char.ord
        end
        parsed_value
      end
    end

    struct Null < Value
      def parsed
        nil
      end

      def account_for_zero
        0
      end
    end

    VALUE_DISPATCH = {
      # Integer values
      LibMySQL::MySQLFieldType::MYSQL_TYPE_TINY => Integer,
      LibMySQL::MySQLFieldType::MYSQL_TYPE_SHORT => Integer,
      LibMySQL::MySQLFieldType::MYSQL_TYPE_LONG => Integer,
      LibMySQL::MySQLFieldType::MYSQL_TYPE_LONGLONG => Integer,
      LibMySQL::MySQLFieldType::MYSQL_TYPE_INT24 => Integer,
      LibMySQL::MySQLFieldType::MYSQL_TYPE_YEAR => Integer,

      # Float values
      LibMySQL::MySQLFieldType::MYSQL_TYPE_DECIMAL => Float,
      LibMySQL::MySQLFieldType::MYSQL_TYPE_FLOAT => Float,
      LibMySQL::MySQLFieldType::MYSQL_TYPE_DOUBLE => Float,
      LibMySQL::MySQLFieldType::MYSQL_TYPE_NEWDECIMAL => Float,

      # Date & Time values
      LibMySQL::MySQLFieldType::MYSQL_TYPE_TIMESTAMP => Datetime,
      LibMySQL::MySQLFieldType::MYSQL_TYPE_DATETIME => Datetime,
      LibMySQL::MySQLFieldType::MYSQL_TYPE_DATE => Date,

      # Bit values
      LibMySQL::MySQLFieldType::MYSQL_TYPE_BIT => Bit,

      # NULL values
      LibMySQL::MySQLFieldType::MYSQL_TYPE_NULL => Null,
    }
  end
end