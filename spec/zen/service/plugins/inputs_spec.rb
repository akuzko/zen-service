# frozen_string_literal: true

require "spec_helper"

RSpec.describe Zen::Service::Plugins::Inputs do
  describe "basic input definition" do
    let(:service_class) do
      Class.new(Zen::Service::Callable) do
        use :inputs

        input :foo
        input :bar

        def call
          foo + bar
        end
      end
    end

    it "accepts inputs as keyword arguments" do
      service = service_class.new(foo: 1, bar: 2)
      expect(service.call).to eq(3)
    end

    it "defines reader methods for inputs" do
      service = service_class.new(foo: 1, bar: 2)
      expect(service.foo).to eq(1)
      expect(service.bar).to eq(2)
    end

    it "raises when required input is missing" do
      expect { service_class.new(foo: 1) }.to raise_error(ArgumentError, /input bar is required/)
    end

    it "raises when unexpected input is provided" do
      expect { service_class.new(foo: 1, bar: 2, baz: 3) }.to raise_error(ArgumentError, /wrong inputs baz given/)
    end
  end

  describe "optional inputs" do
    let(:service_class) do
      Class.new(Zen::Service::Callable) do
        use :inputs

        input :foo
        input :bar, optional: true

        def call
          [foo, bar]
        end
      end
    end

    it "allows omitting optional inputs" do
      service = service_class.new(foo: 1)
      expect(service.call).to eq([1, nil])
    end

    it "still accepts optional inputs when provided" do
      service = service_class.new(foo: 1, bar: 2)
      expect(service.call).to eq([1, 2])
    end
  end

  describe "inputs with default values" do
    let(:service_class) do
      Class.new(Zen::Service::Callable) do
        use :inputs

        input :foo
        input :bar, default: -> { 10 }
        input :baz, default: -> { 20 }

        def call
          foo + bar + baz
        end
      end
    end

    it "uses default value when input is not provided" do
      service = service_class.new(foo: 5)
      expect(service.call).to eq(35)
    end

    it "overrides default value when input is provided" do
      service = service_class.new(foo: 5, bar: 15)
      expect(service.call).to eq(40)
    end
  end

  describe "input with validation block" do
    let(:service_class) do
      Class.new(Zen::Service::Callable) do
        use :inputs

        input :age do |value|
          raise ArgumentError, "age must be positive" if value <= 0
        end

        def call
          age * 2
        end
      end
    end

    it "validates input value" do
      expect { service_class.new(age: -5) }.to raise_error(ArgumentError, /age must be positive/)
    end

    it "accepts valid input" do
      service = service_class.new(age: 10)
      expect(service.call).to eq(20)
    end
  end

  describe "inputs bulk definition" do
    let(:service_class) do
      Class.new(Zen::Service::Callable) do
        use :inputs

        inputs :foo, :bar, baz: -> { 30 }

        def call
          foo + bar + baz
        end
      end
    end

    it "defines multiple inputs at once" do
      service = service_class.new(foo: 10, bar: 20)
      expect(service.call).to eq(60)
    end

    it "supports default values in bulk definition" do
      service = service_class.new(foo: 10, bar: 20, baz: 40)
      expect(service.call).to eq(70)
    end
  end

  describe "inputs with initialization block" do
    let(:service_class) do
      Class.new(Zen::Service::Callable) do
        use :inputs

        attr_reader :computed

        inputs :foo, :bar do |foo_val, bar_val|
          @computed = foo_val * bar_val
        end

        def call
          computed
        end
      end
    end

    it "executes initialization block with input values" do
      service = service_class.new(foo: 3, bar: 4)
      expect(service.call).to eq(12)
    end
  end

  describe "inheritance" do
    let(:base_service) do
      Class.new(Zen::Service::Callable) do
        use :inputs

        input :foo
      end
    end

    let(:child_service) do
      Class.new(base_service) do
        input :bar

        def call
          foo + bar
        end
      end
    end

    it "inherits inputs from parent class" do
      service = child_service.new(foo: 5, bar: 10)
      expect(service.call).to eq(15)
    end

    it "child's inputs don't affect parent" do
      expect(base_service.input_names).to eq([:foo])
      expect(child_service.input_names).to eq(%i[foo bar])
    end
  end

  describe "#initialize_clone" do
    let(:service_class) do
      Class.new(Zen::Service::Callable) do
        use :inputs

        input :foo
        input :bar

        def call
          [foo, bar]
        end
      end
    end

    it "duplicates inputs hash so modifications don't affect clone" do
      service = service_class.new(foo: 1, bar: 2)
      cloned = service.clone

      service.inputs[:foo] = 99

      expect(cloned.foo).to eq(1)
      expect(cloned.call).to eq([1, 2])
    end
  end

  describe ".input_names" do
    let(:service_class) do
      Class.new(Zen::Service::Callable) do
        use :inputs

        input :foo
        input :bar
        input :baz, optional: true
      end
    end

    it "returns list of all input names" do
      expect(service_class.input_names).to eq(%i[foo bar baz])
    end
  end

  describe "multiple initialization blocks" do
    let(:service_class) do
      Class.new(Zen::Service::Callable) do
        use :inputs

        attr_reader :step1, :step2

        inputs :a, :b do |a_val, b_val|
          @step1 = a_val + b_val
        end

        inputs :c do |c_val|
          @step2 = step1 * c_val
        end

        input :c

        def call
          step2
        end
      end
    end

    it "executes all initialization blocks in order" do
      service = service_class.new(a: 2, b: 3, c: 4)
      expect(service.call).to eq(20)
    end
  end

  describe "complex validation scenarios" do
    let(:service_class) do
      Class.new(Zen::Service::Callable) do
        use :inputs

        input :email do |value|
          raise ArgumentError, "invalid email" unless value.include?("@")
        end

        input :age, optional: true do |value|
          raise ArgumentError, "age must be at least 18" if value && value < 18
        end

        def call
          [email, age]
        end
      end
    end

    it "validates required input" do
      expect { service_class.new(email: "invalid") }.to raise_error(ArgumentError, /invalid email/)
    end

    it "validates optional input when provided" do
      expect { service_class.new(email: "test@example.com", age: 15) }
        .to raise_error(ArgumentError, /age must be at least 18/)
    end

    it "skips validation for optional input when not provided" do
      service = service_class.new(email: "test@example.com")
      expect(service.call).to eq(["test@example.com", nil])
    end

    it "accepts valid inputs" do
      service = service_class.new(email: "test@example.com", age: 25)
      expect(service.call).to eq(["test@example.com", 25])
    end
  end
end
