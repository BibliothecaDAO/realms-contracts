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
    member resource_1 : felt  # 
    member resource_2 : felt  # 
    member resource_3 : felt  # 
    member resource_4 : felt  # 
    member resource_5 : felt  # 
    member resource_6 : felt  # 
    member resource_7 : felt  #            
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