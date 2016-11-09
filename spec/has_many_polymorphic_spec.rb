require 'spec_helper'

describe "HasManyPolymorphic" do
  before(:all) do
    Zoo.create(:name => 'Zoo Lander')
    Bear.create(:name => 'Smokey')
    Bird.create(:name => 'Big Bird')
    Monkey.create(:name => 'George')
  end
  
  it "should have created the animals and zoo" do
    expect(Zoo.first.name).to eq 'Zoo Lander'
    expect(Monkey.find_by_name('George').name).to eq 'George'
    expect(Bird.find_by_name('Big Bird').name).to eq 'Big Bird'
    expect(Bear.find_by_name('Smokey').name).to eq 'Smokey'
  end
  
  it "should allow you to add animals to a zoo" do
    zoo = Zoo.first
    expect(zoo.animals.count).to eq 0
    zoo.monkeys << Monkey.find_by_name('George')
    zoo.birds << Bird.find_by_name('Big Bird')
    zoo.bears << Bear.find_by_name('Smokey')
    zoo.save
    
    expect(zoo.monkeys.count).to eq 1
    expect(zoo.monkeys.first.name).to eq 'George'
    
    expect(zoo.birds.count).to eq 1
    expect(zoo.birds.first.name).to eq 'Big Bird'
    
    expect(zoo.bears.count).to eq 1
    expect(zoo.bears.first.name).to eq 'Smokey'
    
    expect(zoo.animals.count).to eq 3
  end
  
  it "should allow you to get the zoo from an animal" do
    zoo = Zoo.first
    
    zoo.monkeys << Monkey.find_by_name('George')
    zoo.birds << Bird.find_by_name('Big Bird')
    zoo.bears << Bear.find_by_name('Smokey')
    zoo.save
    
    monkey = Monkey.find_by_name('George')
    # monkey.zoos.first.id.should eq zoo.id
    expect(monkey.zoos.first.id).to eq zoo.id
   
    bird = Bird.find_by_name('Big Bird')
    expect(bird.zoos.first.id).to eq zoo.id
    
    bear = Bear.find_by_name('Smokey')
    expect(bear.zoos.first.id).to eq zoo.id
  end
end