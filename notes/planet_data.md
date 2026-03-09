planet_data for each frame to determine biome of planet by the sprite frame seleected
0 = Ice
1 = Desert
2 = Forest
3 = Forest
4 = Desert
5 = Rock
6 = Ice
7 = jungle
8 = Rock
9 = Forest
10 = Rock
11 = Ice

Planet types:
Forest, Ice, Rock, Gas, Desert

Gas planets are high in explosions and lava, rocky with little foliage
Rock planets are dense with ores and rocks and lava
Ice planets are covered in ores and ice
Forest planets are covered in dense foliage, ores, and grasses
Desert planets are covered in variations of sand and rich in ores and gems

Planet temps:
Gas = cold
Rock = hot
Ice = cold
Forest = medium
Desert = hot

planet sizes:
Small <= 13,000 kilometers
Medium = > 13,000 kilometers < 48,000 kilometers
Large => 48,000 kilometers


let's work on the foliage system,  i'm going to give you atlas coords for the tileset and then use-cases for those coords and you update the system to only place those coords in those use-cases



stalactite = (5,7) only hangs from ceilling



surface plants = (0,0), (2,0), (3,0), (2, 1), (3, 1), (4, 1), (5, 1), (6, 1), (7, 1), (8, 1), (9, 1), (0, 2), (1, 2), (2, 2), (3, 2),( 4, 2), (6, 2), (8, 2), (9, 2), (2, 3), (3, 3), (4, 3), (5, 3), (6, 3), (7, 3), (8, 3), (9, 3), (0, 4), (1, 4), (2, 4), (3, 4), (4, 4), (5, 4), (6, 4), (9,6)



cave plants = (1,0), (4, 0), (5, 0), (6, 0), (7, 0), (8, 0), (9, 0), (0, 1), (1,  1), (1, 3), (0,3), (7,4), (7, 2),