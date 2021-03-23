# frozen_string_literal: true

module KlarnaGateway
  module AmountCalculators
    module Us
      class ShipmentCalculator
        def adjust_with(shipment)
          yield().merge(
            unit_price: unit_price(shipment),
            total_amount: total_amount(shipment),
            total_tax_amount: total_tax_amount(shipment),
            tax_rate: tax_rate(shipment)
          )
        end

        private

        # In US taxes are calculated on the whole sale.
        # Taxes related to the shipment will be added to the sale tax
        def unit_price(shipment)
          shipment.display_amount.cents
        end

        def total_amount(shipment)
          unit_price(shipment)
        end

        def total_tax_amount(_shipment)
          0
        end

        def tax_rate(_shipment)
          0
        end
      end
    end
  end
end
