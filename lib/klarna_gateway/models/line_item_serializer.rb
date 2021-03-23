module KlarnaGateway
  class LineItemSerializer
    attr_reader :line_item, :strategy

    def initialize(line_item, strategy)
      @line_item = line_item
      @strategy = case strategy
                  when Symbol, String then strategy_for_region(strategy)
                  else strategy
                  end
    end

    # TODO: clarify what amounts exactly should be used
    def to_hash
      strategy.adjust_with(line_item) do
        {
          reference: line_item.sku,
          name: line_item.name,
          quantity: line_item.quantity,
          # Minor units. Includes tax, excludes discount.
          unit_price: unit_price,
          # tax rate, e.g. 500 for 5.00%
          tax_rate: line_item_tax_rate,
          # Includes tax and discount. Must match (quantity * unit_price) - total_discount_amount within ±quantity
          total_amount: total_amount,
          # Must be within ±1 of total_amount - total_amount * 10000 / (10000 + tax_rate). Negative when type is discount
          total_tax_amount: total_tax_amount,
          image_url: image_url,
          product_url: product_url
        }
      end
    end

    private

    def line_item_tax_rate
      # TODO: should we just calculate this?
      tax_rate = line_item.adjustments.tax.inject(0) { |total, tax| total + tax.source.amount }
      (10_000 * tax_rate).to_i
    end

    def total_amount
      display_final_amount = ::Spree::Money.new(line_item.total, currency: line_item.currency)
      display_final_amount.cents
    end

    def total_tax_amount
      pre_tax_amount = line_item.total_before_tax - line_item.included_tax_total
      display_pre_tax_amount = ::Spree::Money.new(pre_tax_amount, currency: line_item.currency)
      total_amount - display_pre_tax_amount.cents
    end

    def unit_price
      line_item.single_money.cents + (total_tax_amount / line_item.quantity).floor
    end

    def image_url
      image = line_item.variant.images.first
      host = image_host

      return unless image.present? && host

      begin
        scheme = "http://" unless host.to_s.match?(%r{^https?://})
        uri = URI.parse("#{scheme}#{host.sub(%r{/$}, '')}#{image.attachment.url}")
      rescue URI::InvalidURIError => e
        return nil
      end
      uri.to_s
    end

    def strategy_for_region(region)
      case region.downcase.to_sym
      when :us then AmountCalculators::Us::LineItemCalculator.new
      else AmountCalculators::Uk::LineItemCalculator.new
        end
    end

    def image_host
      host_conf = KlarnaGateway.configuration.image_host

      case host_conf
      when nil then nil
      when String then host_conf
      when Proc then host_conf.call(line_item)
      end
    end

    def product_url
      product_conf = KlarnaGateway.configuration.product_url

      case product_conf
      when Proc then product_conf.call(line_item)
      end
    end
  end
end
