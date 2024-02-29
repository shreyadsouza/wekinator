// create our OSC receiver
OscIn oscin;
// a thing to retrieve message contents
OscMsg msg;
// use port 12000 (default Wekinator output port)
12000 => oscin.port;

// listen for "/wek/output" message with 4 floats coming in
oscin.addAddress( "/wek/outputs, ffff" );
// print
<<< "listening for OSC message from Wekinator on port 12000...", "" >>>;
<<< " |- expecting \"/wek/outputs\" with 4 continuous parameters...", "" >>>; 

// expecting 4 output dimensions
4 => int NUM_PARAMS;
float myParams[NUM_PARAMS];

// envelopes for smoothing parameters
// (alternately, can use slewing interpolators; SEE:
// https://chuck.stanford.edu/doc/examples/vector/interpolate.ck)
Envelope envs[NUM_PARAMS];
for( 0 => int i; i < NUM_PARAMS; i++ )
{
    envs[i] => blackhole;
    .25 => envs[i].value;
    10::ms => envs[i].duration;
}


SndBuf sounds[NUM_PARAMS];
//  => NRev r[NUM_PARAMS] => dac;
for (auto buf : sounds) buf => dac;


[   
    me.dir() + "stems/guitar.wav",
    me.dir() + "stems/vocals.wav",
    me.dir() + "stems/drums.wav",
    me.dir() + "stems/bass.wav"
] @=> string files[];





for (0 => int i; i < NUM_PARAMS; i++){
    files[i] => sounds[i].read;
    // 0 => sounds[i].pos;
}


fun void setParams( float params[] )
{
    // make sure we have enough
    if( params.size() >= NUM_PARAMS )
    {		
        // adjust the synthesis accordingly
        0.0 => float x;
        for( 0 => int i; i < NUM_PARAMS; i++ )
        {
            // get value
            params[i] => x;
            // clamp it
            if( x < 0 ) 0 => x;
            if( x > 1 ) 1 => x;
            // set as target of envelope (for smoothing)
            x => envs[i].target;
            // remember
            x => myParams[i];
        }
    }
}

// function to map incoming parameters to musical parameters
fun void map2sound()
{
    // time loop
    
    while( true )
    {   
        // make sure we have enough
        for (0 => int i; i < NUM_PARAMS; i++){
            envs[i].value() * .5 => sounds[i].gain;
        }
        10::ms => now;
    }
}

fun void waitForEvent()
{
    // array to hold params
    float p[NUM_PARAMS];

    // infinite event loop
    while( true )
    {
        // wait for OSC message to arrive
        oscin => now;

        // grab the next message from the queue. 
        while( oscin.recv(msg) )
        {
            // print stuff
            cherr <= msg.address <= " ";
            
            // unpack our 5 floats into our array p
            for( int i; i < NUM_PARAMS; i++ )
            {
                // put into array
                msg.getFloat(i) => p[i];
                // print
                cherr <= p[i] <= " ";
            }
            
            // print
            cherr <= IO.newline();
            
            // set the parameters
            setParams( p );
        }
    }
}

// spork osc receiver loop
spork ~waitForEvent();
// spork mapping function
spork ~ map2sound();	
// // turn on sound
// soundOn();

// time loop to keep everything going
while( true ) 1::second => now;
