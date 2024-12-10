// Directly find the gap that's closest
// Then interpolate between the 2
// Answer is scaled to 5000 automatically

// START: DUMB COMMENTS
// A binary search algo for arccos
// Specialized to 32 bit input and 32 bit output
// Outputs as 7FFF = pi and 8000 = -pi
// This is kinda useful for later.

// Approx 32 cycle delay probably
// END: DUMB COMMENTS

module acos (
	input wire clk_in,
	input wire [31:0] acos_in,
	input wire valid_in,
	output logic [31:0] acos_out
);

logic [31:0] acos_vals [0:256]; //initialized below

//find the bounds of acos(in)
logic [23:0] acos_min, acos_max;
always_ff @(posedge clk_in) begin
	acos_min <= acos_vals[acos_in[31:24]];
	acos_max <= acos_vals[acos_in[31:24]+1];
end

//linear interpolate a better value for acos
//takes acos_in[23:0] and 0xFFF-acos_in[23:0] to scale
//then add it up

logic [23:0] min_scale;
logic [23:0] max_scale;

assign min_scale = ~acos_in[23:0];
assign max_scale = acos_in[23:0];

Multiply_re #(
	.WIDTH(24)
) mult_min (
	.a_re(),
	.b_re(),
	.m_re()
);

assign lookup[0] = 24'h138800; // -128 5000.0
assign lookup[1] = 24'h12c0ed; // -127 4800.926572307113
assign lookup[2] = 24'h126e48; // -126 4718.283517620004
assign lookup[3] = 24'h122ebe; // -125 4654.742857429928
assign lookup[4] = 24'h11f911; // -124 4601.069123252318
assign lookup[5] = 24'h11c9af; // -123 4553.687448496634
assign lookup[6] = 24'h119ec3; // -122 4510.765581379156
assign lookup[7] = 24'h117737; // -121 4471.21573982162
assign lookup[8] = 24'h115254; // -120 4434.3295887133945
assign lookup[9] = 24'h112f9d; // -119 4399.615395841092
assign lookup[10] = 24'h110eb7; // -118 4366.715330563276
assign lookup[11] = 24'h10ef5c; // -117 4335.359403086847
assign lookup[12] = 24'h10d156; // -116 4305.337965703191
assign lookup[13] = 24'h10b47c; // -115 4276.48437887588
assign lookup[14] = 24'h1098a9; // -114 4248.663595934603
assign lookup[15] = 24'h107dc3; // -113 4221.764369533067
assign lookup[16] = 24'h1063b1; // -112 4195.693767448338
assign lookup[17] = 24'h104a5f; // -111 4170.373212811179
assign lookup[18] = 24'h1031bc; // -110 4145.735560885997
assign lookup[19] = 24'h1019b9; // -109 4121.722898949248
assign lookup[20] = 24'h100248; // -108 4098.284862021045
assign lookup[21] = 24'h0feb60; // -107 4075.3773239368825
assign lookup[22] = 24'h0fd4f6; // -106 4052.9613663509026
assign lookup[23] = 24'h0fbf00; // -105 4031.002456794592
assign lookup[24] = 24'h0fa978; // -104 4009.4697862183684
assign lookup[25] = 24'h0f9455; // -103 3988.335729762055
assign lookup[26] = 24'h0f7f93; // -102 3967.575403853501
assign lookup[27] = 24'h0f6b2a; // -101 3947.1662994096537
assign lookup[28] = 24'h0f5716; // -100 3927.087975748529
assign lookup[29] = 24'h0f4352; // -99 3907.3218033686517
assign lookup[30] = 24'h0f2fd9; // -98 3887.8507463893175
assign lookup[31] = 24'h0f1ca8; // -97 3868.6591774267886
assign lookup[32] = 24'h0f09bb; // -96 3849.732719186921
assign lookup[33] = 24'h0ef70e; // -95 3831.058108209437
assign lookup[34] = 24'h0ee49f; // -94 3812.6230770928664
assign lookup[35] = 24'h0ed26a; // -93 3794.416252226997
assign lookup[36] = 24'h0ec06d; // -92 3776.4270646087693
assign lookup[37] = 24'h0eaea5; // -91 3758.645671752905
assign lookup[38] = 24'h0e9d10; // -90 3741.0628890561
assign lookup[39] = 24'h0e8bab; // -89 3723.6701292529306
assign lookup[40] = 24'h0e7a75; // -88 3706.4593488274936
assign lookup[41] = 24'h0e696c; // -87 3689.4230004285228
assign lookup[42] = 24'h0e588d; // -86 3672.553990486002
assign lookup[43] = 24'h0e47d8; // -85 3655.845641350855
assign lookup[44] = 24'h0e374a; // -84 3639.291657381403
assign lookup[45] = 24'h0e26e2; // -83 3622.886094485055
assign lookup[46] = 24'h0e169f; // -82 3606.62333269442
assign lookup[47] = 24'h0e067f; // -81 3590.498051416239
assign lookup[48] = 24'h0df681; // -80 3574.5052070413735
assign lookup[49] = 24'h0de6a3; // -79 3558.6400126461103
assign lookup[50] = 24'h0dd6e5; // -78 3542.8979195507486
assign lookup[51] = 24'h0dc746; // -77 3527.2746005316903
assign lookup[52] = 24'h0db7c4; // -76 3511.7659345091993
assign lookup[53] = 24'h0da85e; // -75 3496.367992555082
assign lookup[54] = 24'h0d9913; // -74 3481.0770250836536
assign lookup[55] = 24'h0d89e3; // -73 3465.8894501056866
assign lookup[56] = 24'h0d7acd; // -72 3450.801842439239
assign lookup[57] = 24'h0d6bcf; // -71 3435.810923783539
assign lookup[58] = 24'h0d5ce9; // -70 3420.913553572774
assign lookup[59] = 24'h0d4e1b; // -69 3406.1067205358922
assign lookup[60] = 24'h0d3f63; // -68 3391.387534896676
assign lookup[61] = 24'h0d30c0; // -67 3376.753221155443
assign lookup[62] = 24'h0d2233; // -66 3362.2011113999406
assign lookup[63] = 24'h0d13ba; // -65 3347.7286390984996
assign lookup[64] = 24'h0d0555; // -64 3333.333333333334
assign lookup[65] = 24'h0cf703; // -63 3319.012813436149
assign lookup[66] = 24'h0ce8c3; // -62 3304.76478399198
assign lookup[67] = 24'h0cda96; // -61 3290.5870301805294
assign lookup[68] = 24'h0ccc7a; // -60 3276.4774134272543
assign lookup[69] = 24'h0cbe6f; // -59 3262.4338673390967
assign lookup[70] = 24'h0cb074; // -58 3248.454393902104
assign lookup[71] = 24'h0ca289; // -57 3234.5370599202834
assign lookup[72] = 24'h0c94ae; // -56 3220.679993676945
assign lookup[73] = 24'h0c86e1; // -55 3206.881381801442
assign lookup[74] = 24'h0c7923; // -54 3193.1394663257643
assign lookup[75] = 24'h0c6b73; // -53 3179.452541916771
assign lookup[76] = 24'h0c5dd1; // -52 3165.818953271102
assign lookup[77] = 24'h0c503c; // -51 3152.2370926608864
assign lookup[78] = 24'h0c42b4; // -50 3138.705397619384
assign lookup[79] = 24'h0c3538; // -49 3125.222348756585
assign lookup[80] = 24'h0c27c9; // -48 3111.7864676956156
assign lookup[81] = 24'h0c1a65; // -47 3098.396315121524
assign lookup[82] = 24'h0c0d0c; // -46 3085.0504889347026
assign lookup[83] = 24'h0bffbf; // -45 3071.7476225018227
assign lookup[84] = 24'h0bf27c; // -44 3058.4863829976666
assign lookup[85] = 24'h0be543; // -43 3045.265469831818
assign lookup[86] = 24'h0bd815; // -42 3032.083613154548
assign lookup[87] = 24'h0bcaf0; // -41 3018.9395724367355
assign lookup[88] = 24'h0bbdd5; // -40 3005.8321351189725
assign lookup[89] = 24'h0bb0c2; // -39 2992.7601153254095
assign lookup[90] = 24'h0ba3b8; // -38 2979.7223526381795
assign lookup[91] = 24'h0b96b7; // -37 2966.7177109285603
assign lookup[92] = 24'h0b89be; // -36 2953.7450772412776
assign lookup[93] = 24'h0b7ccd; // -35 2940.803360728621
assign lookup[94] = 24'h0b6fe4; // -34 2927.8914916312633
assign lookup[95] = 24'h0b6302; // -33 2915.0084203028755
assign lookup[96] = 24'h0b5627; // -32 2902.1531162758315
assign lookup[97] = 24'h0b4953; // -31 2889.324567365468
assign lookup[98] = 24'h0b3c85; // -30 2876.521778810528
assign lookup[99] = 24'h0b2fbe; // -29 2863.7437724475703
assign lookup[100] = 24'h0b22fd; // -28 2850.9895859172534
assign lookup[101] = 24'h0b1642; // -27 2838.2582719005463
assign lookup[102] = 24'h0b098c; // -26 2825.5488973830215
assign lookup[103] = 24'h0afcdc; // -25 2812.860542945507
assign lookup[104] = 24'h0af031; // -24 2800.192302079454
assign lookup[105] = 24'h0ae38b; // -23 2787.5432805255036
assign lookup[106] = 24'h0ad6e9; // -22 2774.9125956337743
assign lookup[107] = 24'h0aca4c; // -21 2762.299375744523
assign lookup[108] = 24'h0abdb3; // -20 2749.7027595878562
assign lookup[109] = 24'h0ab11f; // -19 2737.121895701274
assign lookup[110] = 24'h0aa48e; // -18 2724.55594186387
assign lookup[111] = 24'h0a9801; // -17 2712.0040645460667
assign lookup[112] = 24'h0a8b77; // -16 2699.465438373841
assign lookup[113] = 24'h0a7ef0; // -15 2686.9392456064056
assign lookup[114] = 24'h0a726c; // -14 2674.424675626396
assign lookup[115] = 24'h0a65eb; // -13 2661.920924441633
assign lookup[116] = 24'h0a596d; // -12 2649.4271941975576
assign lookup[117] = 24'h0a4cf1; // -11 2636.9426926995
assign lookup[118] = 24'h0a4077; // -10 2624.4666329439506
assign lookup[119] = 24'h0a33ff; // -9 2611.9982326580375
assign lookup[120] = 24'h0a2789; // -8 2599.536713846444
assign lookup[121] = 24'h0a1b14; // -7 2587.081302345013
assign lookup[122] = 24'h0a0ea1; // -6 2574.6312273803223
assign lookup[123] = 24'h0a022f; // -5 2562.1857211345146
assign lookup[124] = 24'h09f5be; // -4 2549.744018314693
assign lookup[125] = 24'h09e94e; // -3 2537.3053557262097
assign lookup[126] = 24'h09dcde; // -2 2524.8689718491705
assign lookup[127] = 24'h09d06f; // -1 2512.4341064175132
assign lookup[128] = 24'h09c400; // 0 2500.0
assign lookup[129] = 24'h09b790; // 1 2487.565893582487
assign lookup[130] = 24'h09ab21; // 2 2475.13102815083
assign lookup[131] = 24'h099eb1; // 3 2462.694644273791
assign lookup[132] = 24'h099241; // 4 2450.2559816853072
assign lookup[133] = 24'h0985d0; // 5 2437.814278865486
assign lookup[134] = 24'h09795e; // 6 2425.368772619678
assign lookup[135] = 24'h096ceb; // 7 2412.9186976549877
assign lookup[136] = 24'h096076; // 8 2400.4632861535565
assign lookup[137] = 24'h095400; // 9 2388.001767341963
assign lookup[138] = 24'h094788; // 10 2375.53336705605
assign lookup[139] = 24'h093b0e; // 11 2363.0573073005003
assign lookup[140] = 24'h092e92; // 12 2350.5728058024424
assign lookup[141] = 24'h092214; // 13 2338.079075558367
assign lookup[142] = 24'h091593; // 14 2325.575324373604
assign lookup[143] = 24'h09090f; // 15 2313.060754393595
assign lookup[144] = 24'h08fc88; // 16 2300.534561626159
assign lookup[145] = 24'h08effe; // 17 2287.9959354539333
assign lookup[146] = 24'h08e371; // 18 2275.4440581361305
assign lookup[147] = 24'h08d6e0; // 19 2262.878104298726
assign lookup[148] = 24'h08ca4c; // 20 2250.297240412144
assign lookup[149] = 24'h08bdb3; // 21 2237.700624255477
assign lookup[150] = 24'h08b116; // 22 2225.0874043662257
assign lookup[151] = 24'h08a474; // 23 2212.456719474497
assign lookup[152] = 24'h0897ce; // 24 2199.807697920546
assign lookup[153] = 24'h088b23; // 25 2187.1394570544935
assign lookup[154] = 24'h087e73; // 26 2174.4511026169785
assign lookup[155] = 24'h0871bd; // 27 2161.741728099454
assign lookup[156] = 24'h086502; // 28 2149.0104140827466
assign lookup[157] = 24'h085841; // 29 2136.25622755243
assign lookup[158] = 24'h084b7a; // 30 2123.4782211894726
assign lookup[159] = 24'h083eac; // 31 2110.6754326345326
assign lookup[160] = 24'h0831d8; // 32 2097.846883724169
assign lookup[161] = 24'h0824fd; // 33 2084.9915796971245
assign lookup[162] = 24'h08181b; // 34 2072.108508368737
assign lookup[163] = 24'h080b32; // 35 2059.1966392713794
assign lookup[164] = 24'h07fe41; // 36 2046.2549227587226
assign lookup[165] = 24'h07f148; // 37 2033.2822890714394
assign lookup[166] = 24'h07e447; // 38 2020.2776473618205
assign lookup[167] = 24'h07d73d; // 39 2007.239884674591
assign lookup[168] = 24'h07ca2a; // 40 1994.1678648810275
assign lookup[169] = 24'h07bd0f; // 41 1981.0604275632647
assign lookup[170] = 24'h07afea; // 42 1967.916386845452
assign lookup[171] = 24'h07a2bc; // 43 1954.7345301681821
assign lookup[172] = 24'h079583; // 44 1941.5136170023334
assign lookup[173] = 24'h078840; // 45 1928.252377498178
assign lookup[174] = 24'h077af3; // 46 1914.9495110652974
assign lookup[175] = 24'h076d9a; // 47 1901.6036848784768
assign lookup[176] = 24'h076036; // 48 1888.2135323043847
assign lookup[177] = 24'h0752c7; // 49 1874.7776512434152
assign lookup[178] = 24'h07454b; // 50 1861.2946023806169
assign lookup[179] = 24'h0737c3; // 51 1847.7629073391136
assign lookup[180] = 24'h072a2e; // 52 1834.181046728898
assign lookup[181] = 24'h071c8c; // 53 1820.5474580832295
assign lookup[182] = 24'h070edc; // 54 1806.8605336742362
assign lookup[183] = 24'h07011e; // 55 1793.1186181985584
assign lookup[184] = 24'h06f351; // 56 1779.3200063230552
assign lookup[185] = 24'h06e576; // 57 1765.4629400797166
assign lookup[186] = 24'h06d78b; // 58 1751.5456060978966
assign lookup[187] = 24'h06c990; // 59 1737.5661326609036
assign lookup[188] = 24'h06bb85; // 60 1723.5225865727464
assign lookup[189] = 24'h06ad69; // 61 1709.4129698194704
assign lookup[190] = 24'h069f3c; // 62 1695.2352160080197
assign lookup[191] = 24'h0690fc; // 63 1680.987186563851
assign lookup[192] = 24'h0682aa; // 64 1666.666666666667
assign lookup[193] = 24'h067445; // 65 1652.2713609015007
assign lookup[194] = 24'h0665cc; // 66 1637.798888600059
assign lookup[195] = 24'h06573f; // 67 1623.2467788445574
assign lookup[196] = 24'h06489c; // 68 1608.612465103325
assign lookup[197] = 24'h0639e4; // 69 1593.8932794641084
assign lookup[198] = 24'h062b16; // 70 1579.0864464272258
assign lookup[199] = 24'h061c30; // 71 1564.1890762164612
assign lookup[200] = 24'h060d32; // 72 1549.198157560762
assign lookup[201] = 24'h05fe1c; // 73 1534.1105498943134
assign lookup[202] = 24'h05eeec; // 74 1518.9229749163464
assign lookup[203] = 24'h05dfa1; // 75 1503.6320074449188
assign lookup[204] = 24'h05d03b; // 76 1488.2340654908012
assign lookup[205] = 24'h05c0b9; // 77 1472.725399468309
assign lookup[206] = 24'h05b11a; // 78 1457.1020804492516
assign lookup[207] = 24'h05a15c; // 79 1441.3599873538894
assign lookup[208] = 24'h05917e; // 80 1425.4947929586267
assign lookup[209] = 24'h058180; // 81 1409.5019485837613
assign lookup[210] = 24'h057160; // 82 1393.3766673055811
assign lookup[211] = 24'h05611d; // 83 1377.1139055149451
assign lookup[212] = 24'h0550b5; // 84 1360.7083426185968
assign lookup[213] = 24'h054027; // 85 1344.1543586491446
assign lookup[214] = 24'h052f72; // 86 1327.4460095139984
assign lookup[215] = 24'h051e93; // 87 1310.5769995714777
assign lookup[216] = 24'h050d8a; // 88 1293.5406511725064
assign lookup[217] = 24'h04fc54; // 89 1276.3298707470692
assign lookup[218] = 24'h04eaef; // 90 1258.9371109439003
assign lookup[219] = 24'h04d95a; // 91 1241.3543282470955
assign lookup[220] = 24'h04c792; // 92 1223.5729353912313
assign lookup[221] = 24'h04b595; // 93 1205.583747773003
assign lookup[222] = 24'h04a360; // 94 1187.3769229071333
assign lookup[223] = 24'h0490f1; // 95 1168.9418917905634
assign lookup[224] = 24'h047e44; // 96 1150.2672808130794
assign lookup[225] = 24'h046b57; // 97 1131.3408225732117
assign lookup[226] = 24'h045826; // 98 1112.149253610682
assign lookup[227] = 24'h0444ad; // 99 1092.6781966313483
assign lookup[228] = 24'h0430e9; // 100 1072.9120242514714
assign lookup[229] = 24'h041cd5; // 101 1052.8337005903463
assign lookup[230] = 24'h04086c; // 102 1032.4245961464999
assign lookup[231] = 24'h03f3aa; // 103 1011.6642702379451
assign lookup[232] = 24'h03de87; // 104 990.5302137816321
assign lookup[233] = 24'h03c8ff; // 105 968.9975432054083
assign lookup[234] = 24'h03b309; // 106 947.0386336490975
assign lookup[235] = 24'h039c9f; // 107 924.6226760631176
assign lookup[236] = 24'h0385b7; // 108 901.7151379789548
assign lookup[237] = 24'h036e46; // 109 878.2771010507523
assign lookup[238] = 24'h035643; // 110 854.2644391140029
assign lookup[239] = 24'h033da0; // 111 829.6267871888206
assign lookup[240] = 24'h03244e; // 112 804.3062325516624
assign lookup[241] = 24'h030a3c; // 113 778.2356304669325
assign lookup[242] = 24'h02ef56; // 114 751.3364040653972
assign lookup[243] = 24'h02d383; // 115 723.5156211241201
assign lookup[244] = 24'h02b6a9; // 116 694.6620342968091
assign lookup[245] = 24'h0298a3; // 117 664.6405969131531
assign lookup[246] = 24'h027948; // 118 633.2846694367238
assign lookup[247] = 24'h025862; // 119 600.3846041589079
assign lookup[248] = 24'h0235ab; // 120 565.6704112866058
assign lookup[249] = 24'h0210c8; // 121 528.7842601783798
assign lookup[250] = 24'h01e93c; // 122 489.234418620844
assign lookup[251] = 24'h01be50; // 123 446.3125515033659
assign lookup[252] = 24'h018eee; // 124 398.93087674768236
assign lookup[253] = 24'h015941; // 125 345.25714257007274
assign lookup[254] = 24'h0119b7; // 126 281.71648237999625
assign lookup[255] = 24'h00c712; // 127 199.0734276928874
assign lookup[256] = 24'h000000; // 128 0.0

endmodule