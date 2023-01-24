(
~hpwd = "/home/jordan/Work/projects/jellyfish"; // home working dir
~pwd = ~hpwd +/+ "sc"; // project working directory
~camwd = ~hpwd +/+ "webcamtrack_mediapipe";
~settings_file_to_load = "control_presets/default.json";

// guitar is stage right
// jellyfish stage left

~outChans = 4;

///////////////////////////////////
// * Launch other progams


~to_unity =    NetAddr("localhost", 12346);
~from_unity =  NetAddr("localhost", 12347);
~from_webcam = NetAddr("localhost", 65313);

fork {
	Server.killAll;
	0.01.wait;

	~launchOtherPrograms = {
		~unity_progam = ~unity_progam ?? {unixCmd(~hpwd +/+ "/jellyfish_unity_builds/buildK.x86_64")};
		~mediapipe = ~mediapipe ?? {unixCmd(~camwd +/+ "/venv/bin/python" + ~camwd +/+ "/main.py -d")};
	};

	~killOtherPrograms = {
		~unity_progam !? { unixCmd("kill " +  ~unity_progam) };
		~mediapipe !? {unixCmd("killall -9 " + ~mediapipe)};
		unixCmd("killall -9 python");

		~unity_progam = nil;
		~mediapipe = nil;
	};

	ServerBoot.add(~launchOtherPrograms);
	ShutDown.add(~killOtherPrograms);
	ServerQuit.add(~killOtherPrograms);
	CmdPeriod.add(~killOtherPrograms);

};

JHCheckUDPListeningPort(~from_webcam);
JHCheckUDPListeningPort(~from_unity);

///////////////////////////////////
// * Server Settings

s.options.memSize = 2.pow(20); // about 1 gb - overkill
s.options.memoryLocking = true; // necessary?
s.options.numInputBusChannels = 2;
s.options.numWireBufs = 1024;
s.options.numOutputBusChannels = 2 + 1 + ~outChans;

"SC_JACK_DEFAULT_INPUTS".setenv("system:capture_3,system:capture_4");
"SC_JACK_DEFAULT_OUTPUTS".setenv("system:playback_1,system:playback_2");

///////////////////////////////////
// * subtargets

~subtargets = JHSubTargets()
.add(\buildDataSets, func: {
	~waterDataSet = JHImport(~pwd +/+ "datasets/water.scd").(
		cachePath: ~pwd +/+ "audio/cache/waterDrops",
		audioFile: ~pwd +/+ "audio/waterDrops.wav"
	);
	~guitarHarmonicsDataSet = JHImport(~pwd +/+ "datasets/guitarHarmonics.scd").();
	~guitarScrapeDataSet = JHImport(~pwd +/+ "datasets/guitarScrape.scd").();
})

.add(\loadSynthDefs, func: {
	PathName(~pwd +/+ "synthDefs/mixins").files.do{ |f| f.fullPath.load };
})

.add(\defineExternalOSC, func: { JHImport(~pwd +/+ "externalOSC.scd").() })

.add(\defineRelayGroup, func: { ~relayGroup = JHGroup(Server.default, 'addToTail') })

.add(\defineIO, [\loadSynthDefs], {
	~inputGroup = JHImport(~pwd +/+ "groups/input/input_group.scd");

	~synthGroup = JHGroup();

	~outputGroup = JHGroup().withGroup {
		JHSynthDef.mkSynth('output/mixer', func: {
			SinkRd.ar('in', ~outChans) * Env([0,0,1], 2, 1).ar(0, 1)
			|> Limiter.ar(_, -1.dbamp, 0.0001)
			|> JHSynthMixin(\AnalysisMixin, _)
			|> {|l| Out.ar(0, [Splay.ar(l), Silent.ar(), l].flat) }
		})
	};
})

.add(\defineMainEffects, [\defineIO], {
	~synthGroup.withGroup {
		~effectGroup = JHGroup(addAction: 'addToTail').withGroup {

			JHImport(~pwd +/+ "groups/effect/reverb.scd").(
				outChans: ~outChans,
				ambiFile: ~pwd +/+ "audio/ir/york_minster_ambi.wav"
			)
			.connect(_.getOut('out'), ['output/mixer', 'in']);

		}
	}
})

.add(\defineMainSynths, [\defineMainEffects, \buildDataSets], {
	~synthGroup.withGroup {
		~mainGroup = JHGroup(addAction: 'addToHead').withGroup {

			JHImport(~pwd +/+ "groups/main/water_grains.scd").(
				outChans: ~outChans,
				waterDataSet: ~waterDataSet,
				numNeighbours: 4
			)
			.connect(_.getOut('out'), ['output/mixer', 'in'])
			.connect(_.getOut('out/wet'), ['effect/reverb', 'in']);

			JHImport(~pwd +/+ "groups/main/slow_water_changes.scd").(
				outChans: ~outChans,
				waterDataSet: ~waterDataSet
			)
			.connect(_.getOut('out'), ['output/mixer', 'in'])
			.connect(_.getOut('out/wet'), ['effect/reverb', 'in']);

			JHImport(~pwd +/+ "groups/main/bass_wobble.scd").(
				outChans: ~outChans
			)
			.connect(_.getOut('out'), ['output/mixer', 'in']);

			JHImport(~pwd +/+ "groups/main/guitar_playback.scd").(
				outChans: ~outChans
			)
			.connect(['in/mic', 'out/mono'], _.getIn('in/mono'))
			.connect(_.getOut('out'), ['output/mixer', 'in'])
			.connect(_.getOut('out/wet'), ['effect/reverb', 'in']);

			JHImport(~pwd +/+ "groups/main/live_echos.scd").(
				outChans: ~outChans
			)
			.connect(['in/mic', 'out/mono'], _.getIn('in/mono'))
			.connect(_.getOut('out'), ['output/mixer', 'in'])
			.connect(_.getOut('out/wet'), ['effect/reverb', 'in']);
		}
	}
})

.add(\defineOSCRelaySynth, [\defineRelayGroup, \defineExternalOSC], {
	~relayGroup.withGroup { JHOSCStore.createRelaySynth(triggerRate: 120) }
})

.add(\defineMainMap, [\defineExternalOSC, \defineMainSynths], {
	// silence - fade in
	(~pwd +/+ "maps/00.scd").load;

	// // section A
	(~pwd +/+ "maps/01.scd").load;
	(~pwd +/+ "maps/02.scd").load;
	(~pwd +/+ "maps/03.scd").load;
	//
	// // transition --  something here isn't working as expected.
	(~pwd +/+ "maps/04.scd").load;

	// section B
	(~pwd +/+ "maps/05.scd").load;

	// 6 is where the strands seperate and there's a lost of cohension
	(~pwd +/+ "maps/06.scd").load;

	// section C
	(~pwd +/+ "maps/07.scd").load;
	(~pwd +/+ "maps/08.scd").load;
})

.add(\defineMainOSCMap, [\defineMainMap, \defineOSCRelaySynth], {
	DebugOut.enable = true;

	~relayGroup.withGroup {
		~jhoscmapper = JHOSCMapperSynth.mkSynth()
	};

	Routine({ loop {
		2.wait;
		postf("current position is : %\n", ~jhoscmapper.busMap['map/number'].bus.getSynchronous());
	}}).play;

})

.add(\synthTester, [\defineMainEffects, \defineOSCRelaySynth, \buildDataSets], {

})

.add(\loadPreviousState, [\defineMainSynths], {
	JHSynthControls.loadFrom(~pwd +/+ ~settings_file_to_load)
});

///////////////////////////////////
// * target launcher

JHLauncher(~subtargets)
.addTarget('Full Piece', [\defineMainOSCMap, \loadPreviousState])
//.addTarget('Full Piece - No Load', [\defineMainOSCMap])
.addTarget('Only External OSC', [\defineExternalOSC, \defineOSCRelaySynth])
.addTarget('Full Piece - No Map', [\loadPreviousState, \defineOSCRelaySynth])
//.addTarget('Synth Tester', [\synthTester])
//.addTarget('Build Data Sets', [\buildDataSets])
.addTarget('Prep For Scratch', [\defineMainSynths])
.addTarget('Data Set Tester', [\buildDataSets])


//.launchTarget('Full Piece')
.mkGUI()

)






