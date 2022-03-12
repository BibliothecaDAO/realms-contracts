%lang starknet

# A struct that holds the Realm statistics.

struct RealmStatistics:
    member defence : felt
    member population : felt
    member magic : felt
    member food_supply : felt
end

struct RealmData:
    member cities : felt  #
    member regions : felt  #
    member rivers : felt  #
    member harbours : felt  # 
    member resource_number : felt  # 
    member resource_1 : felt  # 
    member resource_2 : felt  # 
    member resource_3 : felt  # 
    member resource_4 : felt  # 
    member resource_5 : felt  # 
    member resource_6 : felt  # 
    member resource_7 : felt  #
    member wonder : felt  #
    member order : felt  #              
end

struct ResourceLevel:
    member resource_1_level : felt  # 
    member resource_2_level : felt  # 
    member resource_3_level : felt  # 
    member resource_4_level : felt  # 
    member resource_5_level : felt  # 
    member resource_6_level : felt  # 
    member resource_7_level : felt  #      
end

struct ResourceUpgradeIds:
    member resource_1 : felt  
    member resource_2 : felt  
    member resource_3 : felt   
    member resource_4 : felt  
    member resource_5 : felt      
    member resource_1_values : felt  
    member resource_2_values  : felt  
    member resource_3_values  : felt   
    member resource_4_values  : felt  
    member resource_5_values  : felt       
end

struct RealmBuildings:
    member castles : felt
    member markets : felt
    member aquaducts : felt
    member ports : felt
    member barracks : felt
    member farms : felt
    member temples : felt
    member shipyards : felt
end

struct RealmBuildingCostIds:
    member resource_1 : felt  
    member resource_2 : felt  
    member resource_3 : felt   
    member resource_4 : felt  
    member resource_5 : felt
    member resource_6 : felt  
    member resource_7 : felt  
    member resource_8 : felt   
    member resource_9 : felt  
    member resource_10 : felt           
end

struct RealmBuildingCostValues:     
    member resource_1_values : felt  
    member resource_2_values  : felt  
    member resource_3_values  : felt   
    member resource_4_values  : felt  
    member resource_5_values  : felt       
    member resource_6_values : felt  
    member resource_7_values  : felt  
    member resource_8_values  : felt   
    member resource_9_values  : felt  
    member resource_10_values  : felt     
end