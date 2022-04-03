#!/usr/bin/ruby
# Reads Shopify Payuouts export and generates a NetSuite CSV GL transaction import file 

print  'ruby spo2ns <strftime fmt str> <bank acct> <shopify "bank" acct> <fees acct> <po exports.csv>' if ARGV.length != 5

FILE = String (ARGV.pop)
FEES = Integer(ARGV.pop)
SHOP = Integer(ARGV.pop)
BANK = Integer(ARGV.pop)
DFMT = String (ARGV.pop)

EXPECTED_HEADER = ["Payout Date", "Status", "Charges", "Refunds", "Adjustments", "Reserved Funds", "Fees", "Retried Amount", "Total", "Currency"]

require 'csv'
data = File.open('shopify payouts ENTIRE history to March 4 2022.csv') { |f| CSV.parse(f) }
HEADER = data.shift

# if data is not as expected throw unhandled exception to crash and burn
raise "Unexpected CSV header should equal : '#{EXPECTED_HEADER}'" if HEADER != EXPECTED_HEADER

class StatusException < ArgumentError
  def self.STATUSES
    ['paid','failed','in_transit']
  end
  def self.valid_status? status
    status == StatusException.STATUSES.first
  end
end

require 'date'
# SPO  aka Shopify Payout
class SPORow
  @@datefmt = '%Y-%m-%d'
  def self.datefmt= datefmt; @@datefmt = datefmt; end
  def self.datefmt; @@datefmt; end

  def initialize data
    # Same order as EXPECTED_HEADER
    @date           = Date.parse data.shift
    if !StatusException.valid_status?(@status = data.shift)
      raise StatusException.new "Invalid status '#{@status}' must be one of: '#{StatusException.STATUSES}'" 
    end
    @charges        = data.shift.to_f
    @refunds        = data.shift.to_f
    @adjustments    = data.shift.to_f
    @reserved_funds = data.shift.to_f
    @fees           = data.shift.to_f
    @retried_amount = data.shift.to_f
    @total          = data.shift.to_f
    @currency       = String(data.shift) == 'CAD' ? 1 : 2 # CAD as primary currency IID == 1
  end
  attr_reader :status, :charges, :refunds, :adjustments, :reserved_funds, :fees, :retried_amount, :total, :currency
  def date
    @date.strftime @@datefmt
  end
  def has_refund?
    refunds != 0
  end
end

SPORow.datefmt = DFMT
mapped = data.map { |line| 
  begin
    SPORow.new line
  rescue => e
    throw e if e.class != StatusException
    nil
  end
} 

print CSV.generate { |csv|
  csv << ['Date', 'Account', 'Credit', 'Debit', 'Memo']
  mapped.each { |po|
    next if po == nil

    # output the GL import lines for the payment to the bank from the Shopify account
    # and the fees to the Expense account from the Shopify acct
    # Debit Bank Total and Credit Shopify Bank total
    # Debit Fees Expense > Credit Shopify Bank fees
    def gl_entry csv, date, credit, debit, amount, memo
      csv << [date, credit, amount, 0, memo]
      csv << [date, debit,  0, amount, memo]
    end
    gl_entry(csv, po.date, SHOP, BANK, po.total, "Shopify Payout to Bank #{po.date}")
    gl_entry(csv, po.date, SHOP, FEES, po.fees, "Shopify Fees Expense #{po.date}")
  }
}
