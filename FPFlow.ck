//GLOBAL
40.5 => float PITCH_OFFSET;
//Time in ms
4000 => int BASE_RATE;
//Amount over threshold
0.7 => float SPEED_OFFSET;

0.0 => float FEEDBACK;
0.3 => float VERB;
0.0 => float CHORUS;
0.01 => float VOL;

1000::ms => dur SPEED;
1 => int CHORD_NUMBER;
0 => int OVER_THRESHOLD;
0 => float INPUT_AMOUNT;

// duration to pause when onset detected
100::ms => dur pauseDur;
// threshold
.2 => float threshold;


//=======================COMB FILTER SETUP===================//
//-----------------------------------------------------------------------------
// name: ks-chord.ck
// desc: karplus strong comb filter bank
//
// authors: Madeline Huberth (mhuberth@ccrma.stanford.edu)
//          Ge Wang (ge@ccrma.stanford.edu)
// date: summer 2014
//       Stanford Center @ Peking University
//-----------------------------------------------------------------------------

// single voice Karplus Strong chubgraph
class KS extends Chubgraph
{
    // sample rate
    second / samp => float SRATE;
    
    // ugens!
    DelayA delay;
    OneZero lowpass;
    
    // noise, only for internal use
    Noise n => delay;
    // silence so it doesn't play
    0 => n.gain;
    
    // the feedback
    inlet => delay => lowpass => delay => outlet;
    // max delay
    1::second => delay.max;
    // set lowpass
    -1 => lowpass.zero;
    // set feedback attenuation
    .9 => lowpass.gain;
    
    // mostly for testing
    fun void play( float pitch, dur T )
    {
        tune( pitch ) => float length;
        // turn on noise
        1 => n.gain;
        // fill delay with length samples
        length::samp => now;
        // silence
        0 => n.gain;
        // let it play
        T-length::samp => now;
    }
    
    // tune the fundamental resonance
    fun float tune( float pitch )
    {
        // computes further pitch tuning for higher pitches
        pitch - 43 => float diff;
        0 => float adjust;
        if( diff > 0 ) diff * .0125 => adjust;
        // compute length
        computeDelay( Std.mtof(pitch+adjust) ) => float length;
        // set the delay
        length::samp => delay.delay;
        //return
        return length;
    }
    
    // set feedback attenuation
    fun float feedback( float att )
    {
        // sanity check
        if( att >= 1 || att < 0 )
        {
            <<< "set feedback value between 0 and 1 (non-inclusive)" >>>;
            return lowpass.gain();
        }
        
        // set it        
        att => lowpass.gain;
        // return
        return att;
    }
    
    // compute delay from frequency
    fun float computeDelay( float freq )
    {
        // compute delay length from srate and desired freq
        return SRATE / freq;
    }
}

// chord class for KS
public class KSChord extends Chubgraph
{
    // array of KS objects    
    KS chordArray[4];
    
    // connect to inlet and outlet of chubgraph
    for( int i; i < chordArray.size(); i++ ) {
        inlet => chordArray[i] => outlet;
    }
    
    // set feedback    
    fun float feedback( float att )
    {
        // sanith check
        if( att >= 1 || att < 0 )
        {
            <<< "set feedback value between 0 and 1 (non-inclusive)" >>>;
            return att;
        }
        
        // set feedback on each element
        for( int i; i < chordArray.size(); i++ )
        {
            att => chordArray[i].feedback;
        }
        
        return att;
    }
    
    // tune 4 objects
    fun float tune( float pitch1, float pitch2, float pitch3, float pitch4 )
    {
        pitch1 => chordArray[0].tune;
        pitch2 => chordArray[1].tune;
        pitch3 => chordArray[2].tune;
        pitch4 => chordArray[3].tune;
    }
}
//=======================COMB FILTER HAS BEEN SETUP===================//


//PATCH
StifKarp fish => KSChord object => Chorus choir => NRev rev => Gain gin => dac;
SinOsc sinny => ADSR env => choir => rev => gin => dac;
TriOsc tri => env => choir => rev => gin => dac;
env.set( 400::ms, 30::ms, .5, 200::ms );
env.keyOff;

0.2 => env.gain;
0.01 => gin.gain;

0.3 => rev.mix;
0.0 => choir.mix;
2000 => choir.modFreq;
0.3 => choir.modDepth;
object.feedback(0.0);
0.1 => fish.gain;
0.1 => object.gain;
0.1 => choir.gain;
0.1 => rev.gain;

//=====CHORDS/SCALES =======//

[ 81, 83, 84, 86, 88, 89, 91, 93 ] @=> int aminor[];
[ 81, 84, 88, 84 ] @=> int achord[];
[ 86, 89, 93, 89 ] @=> int dchord[];
[ 88, 91, 95, 91 ] @=> int echord[];
[ 84, 88, 91, 88 ] @=> int cchord[];
[ 89, 93, 95, 93 ] @=> int fchord[];
[ 91, 95, 96, 95 ] @=> int gchord[];

[ 61, 63, 66, 68, 70 ] @=> int pentaScale[];

[ 0, 0, 0, 0 ] @=> int currentChord[];



//Setting Chord
fun void setChord(int chordNumber)
{
    for (int j; j < 4; j++) 
    {
        if (chordNumber == 1) 
        {
            achord[j] - 24 => currentChord[j];
        }
        if (chordNumber == 2) 
        {
            dchord[j] => currentChord[j];
        }
        if (chordNumber == 3) 
        {
            echord[j] => currentChord[j];
        }
        if (chordNumber == 4) 
        {
            cchord[j] => currentChord[j];
        }
        if (chordNumber == 5) 
        {
            fchord[j] => currentChord[j];
        }
        if (chordNumber == 6) 
        {
            gchord[j] => currentChord[j];
        }
    }
}


//========End of Scales ======//

//OUTRO

fun void outro() {
    while (gin.gain() > 0) {
        gin.gain() => float gain2;
        gain2 - 0.05 => gin.gain;
        <<< gin.gain() >>>;
        10::ms => now;
    }
}

//======================KEYBOARD SETUP======================//
// keyboard
Hid kb;
// hid message
HidMsg msg;
if( !kb.openKeyboard( 0 ) ) me.exit();

//key numbers
8 => int KEY_E;
21 => int KEY_R;
20 => int KEY_Q;
26 => int KEY_W;
18 => int KEY_O;
19 => int KEY_P;
82 => int UP;
81 => int DOWN;
30 => int NUM1;
31 => int NUM2;
32 => int NUM3;
33 => int NUM4;
79 => int RIGHT;
80 => int LEFT;


fun void keyBoard() {
    while( true )
    {
        while( kb.recv( msg ) )
        {
            if( msg.which > 256 ) continue;
            if( msg.isButtonDown() )
            {
                <<< msg.which >>>;
                if( msg.which == UP)
                {
                    //Code for Up button  
                    FEEDBACK + 0.05 => FEEDBACK;
                    if (FEEDBACK > 0.99) {
                        0.99 => FEEDBACK;
                    }
                     <<< "FEEDBACK UP: ", FEEDBACK >>>;
                     object.feedback(FEEDBACK);
                }
                if( msg.which == DOWN)
                {
                    //Code for DOWN button  
                    FEEDBACK - 0.05 => FEEDBACK;
                    if (FEEDBACK < 0.1) {
                        FEEDBACK + 0.05 => FEEDBACK;
                    }
                    <<< "FEEDBACK DOWN: ", FEEDBACK >>>;
                    object.feedback(FEEDBACK);
                }
                if( msg.which == KEY_W)
                {
                    //Code for Up button
                    //<<< "RIGHT" >>>;
                    VERB + 0.05 => VERB;
                    if (VERB > 0.99) {
                        VERB - 0.05 => VERB;
                    }
                    <<< "VERB UP: ", VERB >>>;
                    VERB => rev.mix;
                   
                }
                if( msg.which == KEY_Q)
                {
                    
                    VERB - 0.05 => VERB;
                    if (VERB < 0.0) {
                        VERB + 0.05 => VERB;
                    }
                    <<< "VERB DOWN: ", VERB >>>;
                    VERB => rev.mix;
                }
                if( msg.which == KEY_E)
                {
                    CHORUS - 0.05 => CHORUS;
                    if (CHORUS < 0) {
                        0 => CHORUS;
                    }
                    <<< "CHORUS UP: ", CHORUS >>>;
                    CHORUS => choir.mix;
                }
                if( msg.which == KEY_R)
                {
                    CHORUS + 0.05 => CHORUS;
                    if (CHORUS > 0.99) {
                        CHORUS - 0.05 => CHORUS;
                    }
                    <<< "CHORUS UP: ", CHORUS >>>;
                    CHORUS => choir.mix;
                }
                if( msg.which == NUM1)
                {
                    //Code for Up button
                    <<< "NUM1" >>>;
                    1 => CHORD_NUMBER;
                    setChord(CHORD_NUMBER);
                    object.tune(currentChord[0], currentChord[1], currentChord[2], currentChord[3]);
                }
                if( msg.which == NUM2)
                {
                    //Code for Up button
                    <<< "NUM2" >>>;
                    2 => CHORD_NUMBER;
                    setChord(CHORD_NUMBER);
                    object.tune(currentChord[0], currentChord[1], currentChord[2], currentChord[3]);
                }
                if( msg.which == NUM3)
                {
                    //Code for Up button
                    <<< "NUM3" >>>;
                    3 => CHORD_NUMBER;
                    setChord(CHORD_NUMBER);
                    object.tune(currentChord[0], currentChord[1], currentChord[2], currentChord[3]);
                }
                if( msg.which == NUM4)
                {
                    //Code for Up button
                    <<< "NUM4" >>>;
                    4 => CHORD_NUMBER;
                    setChord(CHORD_NUMBER);
                    object.tune(currentChord[0], currentChord[1], currentChord[2], currentChord[3]);
                }
                if( msg.which == KEY_O)
                {
                    VOL - 0.05 => VOL;
                    if (VOL < 0) {
                        0 => VOL;
                    }
                    <<< "VOL DOWN: ", VOL >>>;
                    VOL => gin.gain;
                }
                if( msg.which == KEY_P)
                {
                   VOL + 0.05 => VOL;
                    <<< "VOL UP: ", VOL >>>;
                    VOL => gin.gain;                }
            }
        }
        10::ms => now;
    }
}


//======================KEYBOARD HAS BEEN SETUP======================//




//=================MIC SETUP=================//
// patch
adc => Gain g => blackhole;
// square the input, by chucking adc to g a second time
adc => g;




//=================MIC DONE ============//

//SNDBUFF

// "water"
SndBuf water;
// read
me.dir() + "/water.wav" => water.read;
// left and right nodes for panning
water => object => rev => dac;








//choose random note to play from scale
//play note (how long does it play for?)
//wait a certain amount of time
//get random value between 0 and 4
        
fun void flow() {
    //Determining Pitch
        Math.random2(0, 4) => int randIndex;
        Math.random2(-2, -2) => float randPitchOffset;
        if (OVER_THRESHOLD == 1) {
           Math.random2(1, 3) => randPitchOffset; 
        }
        pentaScale[randIndex] + (12 * randPitchOffset) => Std.mtof => float pitch;
        pitch + PITCH_OFFSET => pitch;
        pitch => fish.freq;
        pitch => sinny.freq;
        pitch => tri.freq;
        0.7 =>fish.noteOn;
        env.keyOn();
        if (OVER_THRESHOLD) {
            (1000 / (1 + (INPUT_AMOUNT * 2)))::ms => now;
        } else {
            500::ms => now;
        }
        
        1 =>fish.noteOff;
        env.keyOff();
}

fun void micInput() {
    while (true) {
        //Determining Playback Speed
        if (g.last() > threshold) {    
            g.last() * 5 => INPUT_AMOUNT;
            1 => OVER_THRESHOLD;   
            <<< "MIC ACTIVE INPUT AMOUNT: ", INPUT_AMOUNT >>>; 
            pauseDur => now;      
        } else {
            0 => OVER_THRESHOLD;
            //<<< "MIC NOT ACTIVE" >>>;
        }
        30::ms =>now;
    }
}

fun void baseFlow() {
    while (true) {
        if (OVER_THRESHOLD == 0) {
            spork ~ flow();
            BASE_RATE::ms => now;
        }
        10::ms => now;
    }
    
}

spork ~ keyBoard();
spork ~ micInput();
spork ~ baseFlow();
//spork ~ flow();


//Main loop
while (true) {
    if (OVER_THRESHOLD == 1) {
        spork ~ flow();
        //1000 only because that was what I used as the original base rate, seems to work well
        (1000 / (1 + (INPUT_AMOUNT * 7)))::ms => now;
    } 
    10::ms =>now; 
}