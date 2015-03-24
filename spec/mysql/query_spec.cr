require "../spec_helper"

module MySQL
  describe Query do
    describe "#to_mysql" do
      it "equals to its value in simple case" do
        Query.new(%{SELECT 1}).to_mysql.should eq(%{SELECT 1})
      end

      context "when some parameters used in query" do
        it "fails if they are not resolved" do
          expect_raises(Errors::MissingParameter, /parameter :activity_filter is missing/) do
            Query.new(%{SELECT * FROM user WHERE updated_at > :activity_filter})
          end
        end

        it "replaces them if they are resolved" do
          Query.new(
            %{SELECT * FROM user WHERE updated_at > :activity_filter},
            {
              "activity_filter" => "25.02.15 00:00:00",
            },
          ).to_mysql
            .should eq(%{SELECT * FROM user WHERE updated_at > '25.02.15 00:00:00'})
        end

        it "works with multiple arguments too" do
          Query.new(
            %{SELECT * FROM event WHERE kind = :event_kind AND priority > :event_priority},
            {
              "event_kind" => "message",
              "event_priority" => 35,
            },
          ).to_mysql
            .should eq(%{SELECT * FROM event WHERE kind = 'message' AND priority > 35})
        end

        it "works with arguments specified more than once too" do
          Query.new(
            %{SELECT * FROM event WHERE kind = :event_kind AND priority > :event_priority AND low_priority <= :event_priority AND exact_priority = :event_priority AND foreign_kind <> :event_kind},
            {
              "event_kind" => "message",
              "event_priority" => 35,
            },
          ).to_mysql
            .should eq(%{SELECT * FROM event WHERE kind = 'message' AND priority > 35 AND low_priority <= 35 AND exact_priority = 35 AND foreign_kind <> 'message'})
        end
      end
    end

    describe "different types of values" do
      it "works with string" do
        Query.new(%{SELECT :a}, {"a" => "hello"}).to_mysql.should eq(%{SELECT 'hello'})
      end

      it "works with int" do
        Query.new(%{SELECT :a}, {"a" => 55}).to_mysql.should eq(%{SELECT 55})
      end

      it "works with float" do
        Query.new(%{SELECT :a}, {"a" => 12.36}).to_mysql.should eq(%{SELECT 12.36})
      end

      it "works with time" do
        Query.new(%{SELECT :a}, {
                    "a" => TimeFormat.new("%F %T").parse("2005-03-27 02:00:00"),
                  }).to_mysql.should eq(%{SELECT '2005-03-27 02:00:00'})
      end

      it "works with date (kinda)" do
        time = TimeFormat.new("%F %T").parse("2005-03-27 02:00:00")
        date = Types::Date.new(time)
        Query.new(%{SELECT :a}, {
                    "a" => date,
                  }).to_mysql.should eq(%{SELECT '2005-03-27'})
      end

      it "works with nil" do
        Query.new(%{SELECT :a}, {"a" => nil}).to_mysql.should eq(%{SELECT NULL})
      end
    end

    describe "escapes strings properly" do
      it "escapes nasty string values" do
        Query.new(%{SELECT :a}, {"a" => "'; DROP TABLE user; --"}).to_mysql
          .should eq(%{SELECT '\\'; DROP TABLE user; --'})
      end
    end
  end
end
