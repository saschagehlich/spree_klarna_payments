# frozen_string_literal: true

module KlarnaGateway
  module AmountCalculators
    module Uk
      class LineItemCalculator
        def adjust_with(line_item)
          yield().merge(
            total_tax_amount: total_tax_amount(line_item),
            tax_rate: tax_rate(line_item),
            unit_price: unit_price(line_item),
            total_amount: total_amount(line_item),
            discount_amount: 0
          )
        end

        private

        def unit_price(line_item)
          line_item.single_money.cents
        end

        def total_amount(line_item)
          line_item.display_amount.cents
        end

        def total_tax_amount(line_item)
          ::Spree::Money.new(tax_total_version(line_item).abs, currency: line_item.currency).cents
        end

        def tax_rate(line_item)
          if line_item.adjustments.tax.count == 1
            (line_item.adjustments.tax.first.source.amount * 10_000).to_i
          else
            0
          end
        end

        def tax_total_version(line_item)
          line_item.amount - line_item.pre_tax_amount
        end
      end
    end
  end
end
