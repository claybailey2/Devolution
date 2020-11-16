/******************************************************/
//CLAY BAILEY MIDTERM PROJECT PART 2

	//ASSEMBLY - "THE SCORE"
	/*************************
	I. INDOOR = Cocktail party fades into escape
	II. MOVING = Driving to the beach
	III. OUTSIDE = Walking on the final leg of our journey to the sea
	*****************************/

(
s.boot;
s.waitForBoot {
	//SET TEMPO
	t = TempoClock.default;
	t.tempo = 60/60;
	//LOAD FILES
	//FILE NAMES
	~b = [
		\apartment_answer, //0
		\apartment_ara,  //1
		\apartment_click,//2
		\apartment_leatherShoes,//3
		\apartment_linetone,//4
		\apartment_loudBoil,//5
		\apartment_softBoil,//6
		\apartment_streamlet,//7
		\car_ignition,//8
		\car_rev,//9
		\car_window,//10
		\miso_chair,//11
		\miso_chatter,//12
		\sandy_birds,//13
		\sandy_crickets,//14
		\sandy_footsteps,//15
		\sandy_rev,//16
		\sandy_shellsteps,//17
		\sandy_waves,//18
		\sandy_wetsteps,//19
		\stairwell_idk,//20
		\stairwell_kadunk,//21
		\stairwell_thud_kadunk,//22
		\stairwell_thud,//23
		\westrock_big,//24
		\westrock_roll,//25
		\westrock_siren,//26
		\westrock_small //27
	].collect{|val| Buffer.read(s,(val++".wav").resolveRelative) };

	"Loaded!".postln;
	//SAMPLE MAP: connects symbols used hereafter to the above buffers
	~bOrder = [
		\answer,
		\ara,
		\tap,
		\shoe,
		\line,
		\L_boil,
		\S_boil,
		\stream,
		\ign,
		\rev,
		\window,
		\chair,
		\chat,
		\bird,
		\cricket,
		\sand,
		\vroom,
		\shell,
		\wave,
		\wet,
		\idk,
		\kadunk,
		\thud_kadunk,
		\thud,
		\L_rock,
		\roll,
		\siren,
		\S_rock
	];
	//FUNCTION CALCULATES DURATION OF BUFFER
	~bDur = {|sym| ~b[~bOrder.indexOf(sym)].numFrames/~b[~bOrder.indexOf(sym)].sampleRate};

	"SYNTH DEFS".postln;
	"Simple Buffer player".postln;
	//plays the buffer once straight through (or truncated if note is shorter than duration)
	SynthDef(\playBuf, {|buffer, dur = 0.25, amp = 1.0, out = 0, rate = 1.0|
		var sig =  PlayBuf.ar(1, buffer, rate, loop: 0);
		var env = EnvGen.kr(Env.linen(0.01,dur,0.01,level:amp),doneAction:2);
		Out.ar(0, (sig*env) !2);
	}).add;

	//pans sinusodially while adjusting playback rate in the same way.
	"pendulum".postln;
	SynthDef(\pendulum, { arg outBus = 0, buffer, rate = 1, mul = 1, swingFreq = 0.25, dur;
		var sig, env, out;
		sig = PlayBuf.ar(
			1,
			buffer,
			rate: rate * 2.pow(SinOsc.kr(swingFreq * 2, 0.5)),//math to map sin wave to rate
			loop: 1    // play the soundfile over and over without stopping
		)
		*
		mul;
		env = EnvGen.kr(Env.linen(2, dur, 2), doneAction: 2);
		out = Pan2.ar(sig*env, SinOsc.kr(swingFreq));
		Out.ar(outBus, out)
	}).add;

	"the waiting room".postln;
	//looping buffer player with the ability to play backward, pan and use reverb
	SynthDef(\room, {|buffer, rate = 1, start = 0, amp = 1, dur = 1, pan = 0, room = 0.0, mix = 0.0, damp = 1.0|
		var samp =  PlayBuf.ar(1, buffer, rate, 1, start, 1);
		var sig = FreeVerb.ar(samp, mix, room, damp);//reverb
		var panned = Pan2.ar(sig, pan);//panning
		var env = EnvGen.kr(Env.linen(0.01, dur, 0.01,level:amp),doneAction:2);
		var out = panned*env;
		Out.ar(0, out)
	}).add;

	//one-use synths: created for their envelopes
	SynthDef(\chatter, {|dur = 10, amp|
		var sig =  PlayBuf.ar(1, ~b[~bOrder.indexOf(\chat)], loop: 1);
		var env = EnvGen.kr(Env.linen(1, 0, (dur - 1)), doneAction: 2);//fade out
		Out.ar(0, (sig*env*amp) !2);
	}).add;

	SynthDef(\waver, {|dur = 10, amp|
		var sig =  PlayBuf.ar(1, ~b[~bOrder.indexOf(\wave)], loop: 1);
		var env = EnvGen.kr(Env.linen((dur - 1), 0, 1), doneAction: 2);//fade in
		Out.ar(0, Pan2.ar((sig*env*amp), 0.5));
	}).add;

	s.sync;

	/******************************************************/

	//INSIDE A ROOM

	//A FUNCTION TO PLACE N EVENTS RANDOMLY IN M SECONDS OF TIME
	//in: timespan, number of breaks =
	//out: (breaks + 1) random gaps that sum to timespan
	~randomSpan = {|span, breaks|
		var ratios, times, gaps;
		ratios = Array.fill(breaks, {1.0.rand});
		ratios = ratios.sort({|a, b| a < b});
		times = Array.fill(breaks, {|i| ratios[i] * span});
		times = times.add(span);
		times = times.addFirst(0);
		//times.postln;
		gaps = Array.fill(breaks, {|i| times[i + 1] - times[i]});
	};
	//SOUNDS USED IN THIS SECTION
	~roomSounds = [
		\chair,
		\shoe,
		\siren,
		\answer,
		\ara,
		\idk
	];
	//LOOK UP BUFS
	~roomBufs = Array.fill(~roomSounds.size, {|i|
		~b[~bOrder.indexOf(~roomSounds[i])]
	});
	//calculate durations of samples
	~roomDurs = Array.fill(~roomSounds.size, {|i|
		var frames, sr, result;
		frames = ~roomBufs[i].numFrames;
		sr = ~roomBufs[i].sampleRate;
		result = frames / sr;});
	//volumes of sounds in this section in the above order
	~roomLevels = [0.1, 0.1, 1, 0.05, 0.025, 0.1];

	//seconds per section
	~roomTime = [10, 10, 10,];
	//sounds per section
	~roomSize = [5, 10, 20];

	//number of all sounds
	~roomSizeSum = 0;
	~roomSize.do({|size|
		~roomSizeSum = ~roomSizeSum + size;
	});

	//init arrays
	~roomOrder = Array.new;
	~roomOrderDurs = Array.new;
	~roomOrderLevels = Array.new;
	~roomOrderSpans = Array.new;

	//for each section
	~roomSize.do({|size, i|
		//choose sounds in any order
		~roomOrder = ~roomOrder.add(Array.fill(size, {~roomBufs.choose}));
		//lookup durs
		~roomOrderDurs = ~roomOrderDurs.add(Array.fill(size, {|j| //add array
			var result;
			result = ~roomDurs[~roomBufs.indexOf(~roomOrder[i][j])];
		}));
		//lookup volumes
		~roomOrderLevels = ~roomOrderLevels.add(Array.fill(size, {|j|
			~roomLevels[~roomBufs.indexOf(~roomOrder[i][j])];
		}));
		//use helper function to space silences out
		~roomSpans = ~roomSpans.add(~randomSpan.(~roomTime[i], size));
	});
	//convert array of Floats to array of Rests
	~roomOrderRests = Array.new;
	~roomTime.do({|time, i|
		~roomOrderSpans = ~roomOrderSpans.add(~randomSpan.(time, ~roomSize[i]));
	});
	~roomOrderSpans.do({|array|
		~roomOrderRests = ~roomOrderRests.add(Array.fill(array.size, {|j|
			var result ;
			result = Rest(array[j]);
			result;
		}));
	});
	//combine duration and rest arrays
	~roomOrderDursRests = Array.new;
	~roomOrderRests.do({|rests, i|
		~roomOrderDursRests = ~roomOrderDursRests.add(Array.new);
		rests.do({|rest, j|
			~roomOrderDursRests[i] = ~roomOrderDursRests[i].add(rest);
			~roomOrderDursRests[i] = ~roomOrderDursRests[i].add(~roomOrderDurs[i][j]);
		});
	});

	//lookup playback speeds
	~roomOrderRates = Array.fill(~roomSize.size, {|i|
		Array.fill(~roomSize[i], {|j|
			[-1, 1].wchoose([2, 3].normalizeSum);
		});
	});

	//start the final step
	~roomPatterns = Array.new;
	~roomSoundCount = 0;

	//no need to nest
	~roomOrder = ~roomOrder.flat;
	~roomOrderDursRests = ~roomOrderDursRests.flat;
	~roomOrderLevels = ~roomOrderLevels.flat;
	~roomOrderRates = ~roomOrderRates.flat;
	//assemble the Pattern for this section
	~roomOrderDursRests.do({|value, i|
		if (value.isRest,
			{
				value.postln;
				~roomPatterns = ~roomPatterns.add(value);
			},
			{
				var j = ((i + 1) / 2) - 1;
				j = j.asInteger;
				j.post;" : ".post;~roomBufs.find([~roomOrder[j]]).postln;
				~roomPatterns = ~roomPatterns.add(
					(
						\instrument: \room,
						\buffer: ~roomOrder[j],
						\dur: value,
						\amp: ~roomOrderLevels[j],
						\rate: ~roomOrderRates[j],
						\pan: 1.0.rand2, //RANDOM PAN
						\mix:  j / ~roomSizeSum,//THE REVERB INTENSIFIES AT THE END OF THE SECTION
						\room: j / ~roomSizeSum,
						\damp: (~roomSizeSum - j) / ~roomSizeSum
					)
				)
			}
		);
	});

	//~roomPatterns.do({|pattern| pattern.postln;});
	//CALCULATE THE TIME OF THE SECTION FOR FUTURE REFERENCE
	~roomTotalTime = 0;
	~roomOrderDursRests.do({|dur|
		if(dur.isRest,
			{~roomTotalTime = ~roomTotalTime + dur.value},
			{~roomTotalTime = ~roomTotalTime + dur}
		)
	});





	/******************************************************/

	//TRANSITION - PLAY SOME SOUNDS IN ORDER
	~transSounds = [
		~b[~bOrder.indexOf(\ign)],
		~b[~bOrder.indexOf(\line)],
		~b[~bOrder.indexOf(\vroom)],
		~b[~bOrder.indexOf(\vroom)],
	];

	~transDurs = Array.fill(~transSounds.size, {|i|
		var frames, sr, result;
		frames = ~transSounds[i].numFrames;
		sr = ~transSounds[i].sampleRate;
		result = frames / sr;});
	~transDurs[1] = ~transDurs[1] * 2;
	~transRates = [1, 0.5, 1, -1];//RATE CHANGES
	~transLevels = [0.25, 0.05, 0.5, 0.5];

	~trans = Pbind(
		\instrument, \room,
		\buffer, Pseq(~transSounds),
		\dur, Pseq(~transDurs),
		\rate, Pseq(~transRates),
		\amp, Pseq(~transLevels)
	);


	/******************************************************/

	//VIKING BOAT WATERFALL
	//USING THE \pendulum SynthDef

	//EACH SOUND GETS THEIR OWN SYNTH, WHICH WILL BE PANNED AND PITCH-ADJUSTED INDEPENDENTLY
	//THE SWINGING SOUNDS WILL BE SLIGHTLY OUT OF PHASE
	~swingSounds = [
		\chat,
		\stream,
		\L_boil,
		\S_boil,
		\rev
	];

	~swingLevels = [0.25, 0.15, 0.25, 0.25, 0.5];//volumes
	~swingPatterns = Array.fill(5, {|i|
		var baseFreq = 0.5, duration = 58, vol = 0.1,
		//"duration" will also be the amount of time it takes for all five sounds to return to the same phase
		buf = ~b[~bOrder.indexOf(~swingSounds[i])];
		var swingFreq = baseFreq - (i / duration);//^math for this
		Pbind(
			\instrument, \pendulum,
			\buffer, buf,
			\swingFreq, swingFreq,
			\mul, ~swingLevels[i] * vol,
			\dur, Pseq([duration, Rest(1)], 2));
	});
	//~swingPatterns.postln;


	/******************************************************/

	//PROBABALISTIC BEAT

	/*Probability data:
	*The following arrays, each declared as ~[sound]Probs, contain a list of data which represent
	*in index 0 the count of a zero-indexed sixteenth note in a 2 measure pattern and
	*in index 1 the relative weight with which that note should be chosen to be included in the pattern
	*/
	"prob data".postln;
	//PERCUSSIVE SAMPLES ORDERED FROM LOWEST TO HIGHEST
	~percLoHi = [
		\thud,//0
		\S_rock,//1
		\L_rock,//2
		\kadunk,//3
		\roll,//4
		\tap, //5
	];


	//HAND CURATED !
	~thudProbs = [
		[0, 5],
		[2, 1],
		[4, 2],
		[6, 1],
		[8, 3],
		[10, 1],
		[12, 2],
		[14, 1],
		[16, 4],
		[18, 1],
		[20, 2],
		[22, 1],
		[24, 3],
		[26, 1],
		[28, 2],
		[30, 1]
	];
	~sRockProbs = [
		[8, 4],
		[12, 3],
		[24, 4],
		[28, 3]
	];
	~lRockProbs = [
		[4, 4],
		[6, 3],
		[12, 4],
		[13, 1],
		[14, 1],
		[15, 1],
		[16, 2],
		[20, 4],
		[22, 3],
		[28, 4],
		[29, 1],
		[30, 3],
		[31, 3]
	];
	~kadunkProbs =[
		[6, 1],
		[10, 3],
		[14, 3],
		[18, 1],
		[22, 3],
		[24, 2],
		[26, 2],
		[27, 1],
		[28, 3],
	];
	~rollProbs = [
		[2, 2],
		[6, 3],
		[10, 2],
		[14, 3],
		[18, 2],
		[22, 3],
		[26, 1],
		[30, 2]
	];
	~tapProbs = Array.fill(32, {|i| [i, 1]});//each sixteenth note will have equal probability

	//All the above probability data
	~percProbs = [~thudProbs, ~sRockProbs, ~lRockProbs, ~kadunkProbs, ~rollProbs, ~tapProbs];
	~percNumChoices = [6, 2, 8, 5, 6, 12];//The number of times the program should wchoose each sound
	//~percNumChoices = [1, 1, 1, 1, 1, 1];
	//percNumChoices = Array.fill(~percProbs.size, {8});

	~percMatrices = List.fill(~percProbs.size, {List.new()});//create empty output arrays
	~tickTime = 0.125;//TEMPO
	"prob beats fxn".postln;
	//Function to output a matrix for a two measure pattern for one sound
	~makeMatrix = {|probs, numChoices|
		//split the data into 16th note and weight
		var choices = Array.fill(probs.size, {|i| probs[i][0]});
		var weights = Array.fill(probs.size, {|i| probs[i][1]});
		//make choices
		var schedule = Array.fill(numChoices, {choices.wchoose(weights.normalizeSum)});
		//make series of notes and rests based on choices
		var matrix = Array.fill(32, {|tick|
			if( schedule.find([tick]) != nil,
				{~tickTime},
				{Rest(~tickTime)}
			);
		});
		//return the beat
		matrix;
	};


	//BUILD UP from only the lowest sound to include all the sounds
	~randomPatterns = Array.fill(~percProbs.size, {|i|
		~makeMatrix.(~percProbs[i], ~percNumChoices[i]);
	});


	~percProbs.do({|probs, i|
		var new;
		for(i, 0, {|j|
			new = ~randomPatterns[j];
			//new.postln;
			2.do({~percMatrices[j] = ~percMatrices[j].add(new)});
		});
		~percProbs.do({|probs k|
			if(k > i,
				{2.do({~percMatrices[k] = ~percMatrices[k].add(Array.fill(32, {Rest(~tickTime)}))})
			});
		});
	});

	//BACK DOWN from all sounds to none
	~randomPatterns = Array.fill(~percProbs.size, {|i|
		~makeMatrix.(~percProbs[i], ~percNumChoices[i]);
	});


	~percProbs.do({|probs, i|
		var new, last;
		last = ~percProbs.size - 1;
		for(0, (last - i), {|j|
			new = ~randomPatterns[j];
			//new.postln;
			2.do({~percMatrices[j] = ~percMatrices[j].add(new)});
		});
		~percProbs.do({|probs k|
			if(k > (last - i),
				{2.do({~percMatrices[k] = ~percMatrices[k].add(Array.fill(32, {Rest(~tickTime)}))})
			});
		});
	});

	//get the buffers referenced by the symbols in ~percLoHi
	~percBuffers = Array.fill(~percProbs.size, {|i|
		~b[~bOrder.indexOf(~percLoHi[i])]
	});
	//solving a nesting issue I dont quite understand
	~percMatrices.do({|matrix, i| ~percMatrices[i] = ~percMatrices[i].flat});

	//make the pbinds to play
	//what about a \sustain argument?
	~probPercPlayers = Array.fill(~percProbs.size, {|i|
		Pbind(\instrument, \playBuf, \buffer, ~percBuffers[i], \dur, Pseq(~percMatrices[i], 1));
	});



	/******************************************************/

	//FOOTSTEPS
	//feet on different surfaces
	~feetSounds = [
		~b[~bOrder.indexOf(\shell)],
		~b[~bOrder.indexOf(\sand)],
		~b[~bOrder.indexOf(\wet)],
	];
	//calculate durations
	~feetDurs = Array.fill(~feetSounds.size, {|i|
		var frames, sr, result;
		frames = ~feetSounds[i].numFrames;
		sr = ~feetSounds[i].sampleRate;
		result = frames / sr;});
	//number of 8-pace sound bytes to queue
	~feetSize = 10;
	//choose randomly
	~feetOrder = Array.fill(~feetSize, {~feetSounds.choose});

	~feetOrderDurs = Array.fill(~feetSize, {|i|
		~feetDurs.at(~feetSounds.indexOf(~feetOrder[i]))}
	);
	//SECTION LENGTH FOR LATER USE
	~feetTotalTime = 0;
	~feetOrderDurs.do({|dur|
		if(dur.isRest,
			{~feetTotalTime = ~feetTotalTime + dur.value},
			{~feetTotalTime = ~feetTotalTime + dur}
		)
	});

	~feet = Pbind(\instrument, \playBuf, \buffer, Pseq(~feetOrder), \dur, Pseq(~feetOrderDurs));
	~beachTime = ~feetTotalTime + 12;


	/******************************************************/
	//ASSEMBLY - "THE SCORE"
	/*************************
	I. INDOOR = Cocktail party moves into despair
	II. MOVING = Driving to the beach
	III. OUTSIDE = Walking on the final leg of our journey
	*****************************/
	/******************************************************/
	//SECTION I
	~breakSize = 100;
	~breakDurs = Array.fill(~breakSize, {[1, 2, 3, 4].choose * 0.125});
	~breakAmps = Array.fill(~breakSize, {[0, 0.1].wchoose([1, 2].normalizeSum)});
	~breakRates = Array.fill(~breakSize, {[-1, 1].wchoose([1, 2].normalizeSum)});

	(
		\instrument: \chatter,
		\dur: ~roomTotalTime,
		\amp: 0.1
	).play;
	Pseq(~roomPatterns).play;

	Pseq([
		(\dur: Rest(~roomTotalTime)),
		(
			\instrument: \room,
			\buffer: ~b[~bOrder.indexOf(\ara)],//VOCAL
			\dur: 2,
			\amp: 0.2,
			\mix:  0.9,
			\room: 0.9,
			\damp: 0
		),
		//SECTION II
		~trans,//CAR DRIVES OFF
		Ppar([
			Pseq([
				(
					\dur: 2,
					\amp: 0
				),
				(
					\instrument: \room,
					\buffer: ~b[~bOrder.indexOf(\window)],//OPEN OUR WINDOW
					\dur: ~bDur.(\window),
					\amp: 0.1,
					\pan: -0.5
				),
				Pseq([
					(
						\instrument: \room,
						\buffer: ~b[~bOrder.indexOf(\bird)],//LET THE BREEZE IN
						\dur: ~bDur.(\bird),
						\amp: 0.25,
						\pan: -0.8
				)], 5),
				(
					\dur: 24,
					\amp: 0
				),
				Ppar([
					Pseq([
						(
							\instrument: \room,
							\buffer: ~b[~bOrder.indexOf(\bird)],
							\dur: ~bDur.(\bird),
							\amp: 0.5,
							\pan: -0.6
					)], 5),
					Pbind(*[
						\instrument: \room,
						\buffer: ~b[~bOrder.indexOf(\answer)],
						\dur: Pseq(~breakDurs),
						\amp: Pseq(~breakAmps),
						\rate: Pseq(~breakRates),
						\pan: 0.4
					])
				]),
				Pbind(*[
					\instrument: \room,
					\buffer: ~b[~bOrder.indexOf(\line)],//JINGLE
					\dur: Pseq([~bDur.(\line)/0.2], 2),
					\amp: 0.05,
					\rate: 0.2,
					\mix:  0.4,
					\room: 0.3,
					\damp: 0.5
				]),
			]),
			Ppar(~swingPatterns),//VIKING BOAT: two full cycles
			Pseq([
				(
					\dur: 10,
					\amp: 0
				),
				Ppar(~probPercPlayers),//PROBABLISTIC PERCUSSION
				(
					\dur: 10,
					\amp: 0
				),
			]),
			Pseq([
				(
					\dur: 120,
					\amp: 0
				),
				(
					\instrument: \room,
					\buffer: ~b[~bOrder.indexOf(\window)],//CLOSE OUR WINDOW
					\dur: ~bDur.(\window),
					\amp: 0.1,
					\rate: -1,
					\pan: -0.5
				),
			]),
		]),
		Pseq([

			Pbind(*[
				\instrument: \room,
				\buffer: ~b[~bOrder.indexOf(\line)],//JINGLE
				\dur: Pseq([
					Pseq([~bDur.(\line)/1.5],3),
					Pseq([~bDur.(\line)])
				]),
				\amp: 0.2,
				\rate: Pseq([
					Pseq([-1.5],3),
					Pseq([-1])
				]),
				\mix:  0.4,
				\room: 0.6,
				\damp: 0
			]),
		]),
		Ppar([
			Pbind(*[
				\instrument: \waver,
				\dur: Pseq([~beachTime, Rest(10)]),//APPROACHING THE WAVES
				\amp: 0.1
			]),

			Pseq([
				(
					\amp: 0,
					\dur: ~beachTime/3
				),
				(
					\instrument: \room,
					\buffer: ~b[~bOrder.indexOf(\cricket)],//BUGS GREET US WITH SONG
					\dur: 2*~beachTime/3,
					\amp: 1,
					\pan: -0.5
				)
			]),

			Pseq([
				(
					\amp: 0,
					\dur: 2*~beachTime/3
				),

				(
					\instrument: \room,
					\buffer: ~b[~bOrder.indexOf(\bird)],//BIRDS ARE IRRITATED BY OUR PRESENCE
					\dur: ~beachTime/3,
					\amp: 0.5,
					\pan: 0.4
				)
			]),

			Pbind(
				\instrument, \playBuf,
				\buffer, Pseq(~feetOrder),
				\dur, Pseq(~feetOrderDurs)//THE STEPS WE TAKE
			),

			Pbind(*[
				\instrument: \room,
				\buffer: ~b[~bOrder.indexOf(\line)],
				\dur: Pseq([~bDur.(\line)/0.2], 1),//LOWJINGLE
				\amp: 0.05,
				\rate: 0.2,
				\mix:  0.4,
				\room: 0.3,
				\damp: 0.5
			]),
			Pbind(*[
				\instrument: \room,
				\buffer: ~b[~bOrder.indexOf(\line)],
				\dur: Pseq([~bDur.(\line)/0.1], 2),//LOWJINGLE
				\amp: 0.1,
				\rate: -0.1,
				\mix:  0.4,
				\room: 0.3,
				\damp: 0.5
			])
		]),

		//CODA
		Ppar([
			Pseq([
				Pseq([
					(
						\instrument: \room,
						\buffer: ~b[~bOrder.indexOf(\ara)],//GRANULARIZED VOCAL 1
						\dur: 0.1,
						\amp: 0.2,
						\mix:  0.9,
						\room: 0.9,
						\damp: 0,
						\start: 9000,
						\pan: 0.3
				)], 30),
				(rest: Rest(1))
			]),
			Pseq([
				(rest: Rest(~feetTotalTime + 2.55)),
				//I'm having a hard time understanding how the program counts these rests
				Pseq([
					(
						\instrument: \room,
						\buffer: ~b[~bOrder.indexOf(\idk)],//GRANULARIZED VOCAL 2
						\dur: 0.1,
						\amp: 0.3,
						\mix:  0.9,
						\room: 0.9,
						\damp: 0,
						\start: 20000,
						\pan: -0.7
				)], 30),
				(rest: Rest(1)),
			]),

			Pbind(*[
				\instrument: \room,
				\buffer: ~b[~bOrder.indexOf(\line)],
				\dur: Pseq([~bDur.(\line)/0.67, ~bDur.(\line)/1, ~bDur.(\line)/2, ~bDur.(\line)/2,], 1),
				//THE CHIMES THAT FINISH
				\amp: 0.1,
				\rate: 0.15,
				\mix:  0.4,
				\room: 0.3,
				\damp: 0.5,
			]),
			Pbind(*[
				\instrument: \room,
				\buffer: ~b[~bOrder.indexOf(\thud_kadunk)],
				\dur: Pseq([~bDur.(\thud_kadunk)], 5),
				\amp: 0.1,
				\rate: 0.85,
				\mix:  0.4,
				\room: 0.3,
				\damp: 0.5,
			])
		])
	]).play;

}
)