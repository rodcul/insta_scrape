require 'spec_helper'

describe InstaScrape do

  it 'Keep 100 at 100' do
    expect(InstaScrape.reverse_human_to_number("100")).to eq(100)
  end

  it 'Convert 1,000 to 1000' do
    expect(InstaScrape.reverse_human_to_number("1,000")).to eq(1000)
  end

  it 'Convert 1,201 to 1201' do
    expect(InstaScrape.reverse_human_to_number("1,201")).to eq(1201)
  end

  it 'Convert 15,000 to 15000' do
    expect(InstaScrape.reverse_human_to_number("15,000")).to eq(15000)
  end

  it 'Convert 1,500,200 to 1500200' do
    expect(InstaScrape.reverse_human_to_number("1,500,200")).to eq(1500200)
  end

  it 'Convert 23.3k to 23300' do
    expect(InstaScrape.reverse_human_to_number("23.3k")).to eq(23300)
  end

  it 'Convert 133m to Integer' do
    expect(InstaScrape.reverse_human_to_number("133m")).to eq(133000000)
  end

  it 'Return nil if Gobbledegoob' do
    expect(InstaScrape.reverse_human_to_number("Gobbledegoob")).to eq(nil)
  end
end
