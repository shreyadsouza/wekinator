// create our OSC receiver
OscIn oscin;
// a thing to retrieve message contents
OscMsg msg;
// use port 12000 (default Wekinator output port)
12000 => oscin.port;

// listen for "/wek/output" message with 5 floats coming in
oscin.addAddress( "/wek/outputs, fffff" );
// print
<<< "listening for OSC message from Wekinator on port 12000...", "" >>>;
<<< " |- expecting \"/wek/outputs\" with 4 continuous parameters...", "" >>>; 

// expecting 4 output dimensions
5 => int NUM_PARAMS;
float myParams[NUM_PARAMS];

// envelopes for smoothing parameters
// (alternately, can use slewing interpolators; SEE:
// https://chuck.stanford.edu/doc/examples/vector/interpolate.ck)
SndBuf sound => dac;

[   
    me.dir() + "data/boyfriend.wav",
    me.dir() + "data/eenie-meenie.wav",
    me.dir() + "data/lonely.wav",
    me.dir() + "data/one-less-lonely-girl.wav",
    me.dir() + "data/where-ru-now.wav"
] @=> string files[];
string filename;
0 => int prev_val;
0 => int curr_val;


fun void setParams( float params[] )
{
    // make sure we have enough
    for (0 => int i; i < params.size(); i++){
        if (params[i] > 0.95){
            files[i] => filename;
            curr_val => prev_val;
            i => curr_val;
        }
    }
}



// function to map incoming parameters to musical parameters
fun void map2sound()
{
    // time loop
    
    while( true )
    {   
        if (prev_val != curr_val ) {
            <<<filename>>>;
            filename => sound.read; 
            curr_val => prev_val;
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
