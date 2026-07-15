NOP
#PRNAME PMU_padrao
#NUBITS 32
#NBMANT 23
#NBEXPO 8
#NDSTAC 64
#SDEPTH 32
#NUIOIN 1
#NUIOOU 4
#NUGAIN 128
#array w0 2 164
#array cosd 2 32
#array sind 2 32
#array bufr 2 164
#array bufi 2 164
@main LOD 0
SET main_ii
LOD 0.0
SET main_ang
@Lwh1 LOD 32
LES main_ii
JIZ Lwh1end
LOD main_ii
P_LOD main_ang
F_NEG
F_ADD 1.570796327CAL float_sin
STI cosd
LOD main_ii
P_LOD main_ang
CAL float_sin
STI sind
LOD main_ang
F_ADD 0.1963495408
SET main_ang
LOD main_ii
ADD 1
SET main_ii
JMP Lwh1
@Lwh1end LOD 0.0
SET main_sumw
LOD 0.0
SET main_fk
LOD 0
SET main_ii
@Lwh2 LOD 164
LES main_ii
JIZ Lwh2end
LOD 82
EQU main_ii
JIZ Lif1else
LOD main_ii
P_LOD 1.0
STI w0
JMP Lif1end
@Lif1else LOD main_fk
F_SU1 82.0
F_MLT 0.0536034247
SET main_a
LOD 0.0385471491
F_MLT main_fk
F_NEG
F_ADD 1.570796327CAL float_sin
F_MLT 0.46
F_SU2 0.54
SET main_h
LOD main_ii
P_LOD main_a
CAL float_sin
P_LOD main_a
SF_DIV
F_MLT main_h
STI w0
@Lif1end LOD main_ii
LDI w0
F_ADD main_sumw
SET main_sumw
LOD main_fk
F_ADD 1.0
SET main_fk
LOD main_ii
ADD 1
SET main_ii
JMP Lwh2
@Lwh2end LOD main_sumw
F_DIV 1.4142135624
SET main_sc
LOD 0
SET main_ii
@Lwh3 LOD 164
LES main_ii
JIZ Lwh3end
LOD main_ii
P_LOD main_ii
LDI w0
F_MLT main_sc
STI w0
LOD main_ii
ADD 1
SET main_ii
JMP Lwh3
@Lwh3end LOD 0
SET main_ii
@Lwh4 LOD 164
LES main_ii
JIZ Lwh4end
LOD main_ii
P_LOD 0.0
STI bufr
LOD main_ii
P_LOD 0.0
STI bufi
LOD main_ii
ADD 1
SET main_ii
JMP Lwh4
@Lwh4end LOD 0
SET wr
LOD 0
SET nsmp
LOD 60.0
SET feprev
LOD 0.0
P_LOD 0.0
SET_P yprev_i
SET yprev
@fim JMP fim
#ITRAD
F_INN 0
F_MLT 0.00000095367431640625
SET main_x
LOD 31
AND nsmp
SET main_ph
LDI cosd
F_MLT main_x
SET main_yr
LOD main_ph
LDI sind
F_MLT main_x
SET main_yi
LOD wr
P_LOD main_yr
STI bufr
LOD wr
P_LOD main_yi
STI bufi
LOD 0.0
SET main_accr
LOD 0.0
SET main_acci
LOD wr
SET main_idx
LOD 0
SET main_k
@Lwh5 LOD 164
LES main_k
JIZ Lwh5end
LOD main_k
LDI w0
P_LOD main_idx
LDI bufr
SF_MLT
F_ADD main_accr
SET main_accr
LOD main_k
LDI w0
P_LOD main_idx
LDI bufi
SF_MLT
F_ADD main_acci
SET main_acci
NEG_M 1
ADD main_idx
SET main_idx
LOD 0
LES main_idx
JIZ Lif2else
LOD 163
SET main_idx
@Lif2else LOD main_k
ADD 1
SET main_k
JMP Lwh5
@Lwh5end LOD wr
ADD 1
SET wr
LOD 163
GRE wr
JIZ Lif3else
LOD 0
SET wr
@Lif3else LOD 0.0
F_SU1 main_acci
SET main_yi_out
LOD main_accr
P_LOD main_yi_out
SET_P main_y_i
SET main_y
LOD 0
EQU nsmp
JIZ Lif4else
LOD 0.0
SET main_dphi
JMP Lif4end
@Lif4else LOD yprev
PF_NEG_M yprev_i
SET_P aux_var 
SET   aux_var1
F_MLT main_y
P_LOD main_y_i
F_MLT aux_var 
SF_SU2
P_LOD main_y
F_MLT aux_var 
P_LOD main_y_i
F_MLT aux_var1
SF_ADD
SET_P main_rot_i
SET main_rot
LOD 0.0
F_LES main_rot
JIZ Lfa1a
LOD main_rot
F_DIV main_rot_i
CAL float_atan
SET fase_t
LOD 0.0
F_LES main_rot_i
JIZ Lfa1b
LOD fase_t
F_ADD -3.14159265359
JMP Lfa1z
@Lfa1b LOD fase_t
F_ADD 3.14159265359
JMP Lfa1z
@Lfa1a LOD main_rot
F_LES 0.0
JIZ Lfa1c
LOD main_rot
F_DIV main_rot_i
CAL float_atan
JMP Lfa1z
@Lfa1c LOD main_rot_i
F_LES 0.0
JIZ Lfa1d
LOD 1.57079632679
JMP Lfa1z
@Lfa1d LOD 0.0
F_LES main_rot_i
JIZ Lfa1e
LOD -1.57079632679
JMP Lfa1z
@Lfa1e LOD 0.0
@Lfa1z SET main_dphi
@Lif4end LOD 305.5774908
F_MLT main_dphi
F_ADD 60.0
SET main_fe
F_SU1 feprev
SET main_rocof
LOD main_accr
F_MLT 1048576.0
F2I
OUT 0
LOD main_yi_out
F_MLT 1048576.0
F2I
OUT 1
LOD main_fe
F_MLT 1048576.0
F2I
OUT 2
LOD main_rocof
F_MLT 1048576.0
F2I
OUT 3
#TOAQUI
LOD main_y
SET yprev
LOD main_y_i
SET yprev_i
LOD main_fe
SET feprev
LOD nsmp
ADD 1
SET nsmp
@fim JMP fim

// Arctangent function --------------------------------------------------------
// |x| is folded into [0,1] with the 1/x identity: atan(|x|) = pi/2 - atan(1/|x|)
// for |x|>1. atan(t) on [0,1] is a degree-11 odd minimax polynomial (least-
// squares fit, max abs error ~4.9e-6 -- ~6 digits, vs the old 49-point LUT's
// ~4e-5). One shared polynomial for both branches; no table, no new hardware.

@float_atan SET   atan_x                 // save x
            F_ABS_M atan_x               // ax = |x|
            SET   atan_ax
            F_LES 1.0                    // (ax > 1)?  [F_LES true when acc > X]
            SET   atan_big               // flag: 1 if |x|>1 (use 1/x)
            JIZ   L_atan_small
            LOD   atan_ax                // big branch: t = 1/ax
            F_DIV 1.0                    // 1.0 / ax   (F_DIV X = X/acc)
            JMP   L_atan_haveT
@L_atan_small LOD atan_ax               // small branch: t = ax
@L_atan_haveT SET atan_t

            F_MLT atan_t                 // w = t^2
            SET   atan_w
            LOD  -0.012300666580         // Horner in w: atan(t)/t = a1 + a3 w + ... + a11 w^5
            F_MLT atan_w                 // a11
            F_ADD 0.054084934779         // a9
            F_MLT atan_w
            F_ADD -0.117697073484        // a7
            F_MLT atan_w
            F_ADD 0.194020561451         // a5
            F_MLT atan_w
            F_ADD -0.332694520616        // a3
            F_MLT atan_w
            F_ADD 0.999980069822         // a1
            F_MLT atan_t                 // * t  -> atan(t)
            SET   atan_p

            LOD   atan_big
            JIZ   L_atan_done            // |x|<=1 -> result = atan(t)
            LOD   atan_p                 // |x|>1  -> result = pi/2 - atan(1/x)
            F_SU2 1.5707963268           // pi/2 - p   (F_SU2 X = X - acc)
            JMP   L_atan_sign
@L_atan_done LOD atan_p
@L_atan_sign F_SGN atan_x                // apply the sign of x
            RET

// Sine function --------------------------------------------------------------
// O(1) range reduction to [-pi/2, pi/2]: k = round(x/pi); r = x - k*pi; then
// sin(x) = (-1)^k * sin(r). sin(r) is a degree-7 odd minimax polynomial (the
// coefficients are a least-squares fit on [0, pi/2], max abs error ~1.6e-6 --
// ~6 digits, vs the old 152-point LUT's ~3). No lookup table, no new hardware.
// NB: F2I truncates toward zero, so round-to-nearest uses a sign-half bias.

@float_sin  SET   sin_x                  // save x
            F_MLT 0.3183098862           // q = x / pi   (1/pi)
            SET   sin_q
            LOD   0.5
            F_SGN sin_q                  // copysign(0.5, q)
            F_ADD sin_q                  // q + copysign(0.5,q)
            F2I                          // k = round(q)
            SET   sin_k                  // keep k (int) for the (-1)^k sign
            I2F                          // float(k)
            F_MLT 3.1415926536           // k * pi
            F_SU2 sin_x                  // r = x - k*pi  -> [-pi/2, pi/2]
            SET   sin_r
            F_MLT sin_r                  // w = r^2
            SET   sin_w

            LOD  -0.000184472138         // Horner in w: sin(r)/r = a1 + a3 w + a5 w^2 + a7 w^3
            F_MLT sin_w                  // a7
            F_ADD 0.008309516704         // a5
            F_MLT sin_w
            F_ADD -0.166651680787        // a3
            F_MLT sin_w
            F_ADD 0.999997487148         // a1
            F_MLT sin_r                  // * r  -> sin(r)
            SET   sin_p

            LOD   sin_k
            AND   1                      // k & 1  (parity)
            JIZ   L_sin_even             // k even -> +sin(r)
            LOD   sin_p
            F_NEG                        // k odd  -> -sin(r)
            RET
@L_sin_even LOD   sin_p
            RET
