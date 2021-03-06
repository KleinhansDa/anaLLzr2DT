///////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////
///////////								MACRO INSTRUCTIONS			 		        ///////////	
///////////////////////////////////////////////////////////////////////////////////////////////
/////////// To use this macro you need to open a (segmented) binary and the 		///////////
/////////// according original image data, then press Run, then follow instructions.///////////
///////////	It was designed to Analyze (shape & nuclei number) and register 		///////////
/////////// the movement of the dr pLLP in Timelapse data.							///////////
///////////////////////////////////////////////////////////////////////////////////////////////
///////////								OPTIMIZED FOR... 						    ///////////
///////////			- 25x microscopic data of the 								    ///////////
///////////			- zebrafish lateral line system	Timelapse data					///////////
/////////// 		- cldnb:lyn-gfp Label & H2BRFP labeling		   					///////////
///////////////////////////////////////////////////////////////////////////////////////////////
///////////         			     David Kleinhans, 22.06.2016				    ///////////
///////////						  Kleinhansda@bio.uni-frankfurt.de				    ///////////
///////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////	
	
// ################### GET PARAMETERS & DIRECTORIES, SHOW DIALOGS ######################
	
// Start up / get Screen parameters to set location of Dialog Boxes
	version = 0.95;
	header = "pLLP ANALYZERv"+version+" ";
	scrH = screenHeight();
		DiaH = scrH/5;
		InfoH = scrH/5;
	scrW = screenWidth();
		DiaW = scrW/6;
		InfoW = scrW/3;
		
// Check if plugins are installed
	//plugins = getDirectory("plugins");
	//pluginlist = getFileList(plugins);
	//mlj = plugins + File.separator + "MorphoLibJ_-1.3.1.jar"
		//if (!File.exists(mlj)) 
			//exit("Please install the 'Morpholib J' plugin first. \nGo to 'Help' -> 'Update...' -> 'Manage Update Sites' -> Choose 'IJPB-plugins'n\Click 'Close', then 'Apply changes'.n\Restart ImageJ and the pLLP Analyzer.");
		
	
// OPENING DIALOG
	guideI();
	String.resetBuffer;
	showStatus("STEP I / III: Data selection...");
	Dialog.create(header+"- STEP I / III");
	Dialog.setLocation(DiaW,DiaH);
	  Dialog.addMessage("Please define some parameters first...");
	  Dialog.addMessage("STEP   I: Data selection");
	  	  Dialog.addCheckbox("RAW data", true);
	  	  Dialog.addCheckbox("Pre-processed", false);
	  //Dialog.addMessage("STEP   I: Data selection");
	  	  Dialog.addCheckbox("Time-Series", true);
	  	  Dialog.addCheckbox("Multichannel (nuclei count)", false);
	  Dialog.addMessage("click 'HELP' for info");
	info(); // info Log
	pre = Dialog.getCheckbox();
	Dialog.show();
	selectWindow(header);
	run("Close");

// 	Input and Output directories
	guideI2();
	if (pre) {
		showStatus("STEP I / II: 8-/16-bit input");
		orgdir	= getDirectory("choose input directory: unprocessed 8-/16-bit image data");
		orgdirlist = getFileList(orgdir);
			par = File.getParent(orgdir); // get org parent directory
		bindir = par + File.separator + "(3) Binaries" + File.separator; // create directory to save binaries in
			File.makeDirectory(bindir);
		rcdir = par + File.separator + "(2) RC" + File.separator; // create directory to save binaries in
			File.makeDirectory(rcdir);
		output = par + File.separator + "(5) Analysis results" + File.separator; // create directory to save binaries in
			File.makeDirectory(output);
		pLLPdir = par + File.separator + "(4) pLLP registered" + File.separator; // create directory to save binaries in
			File.makeDirectory(pLLPdir);
	  	//orglength = ofl.length;
	  	//showStatus("STEP 1/2: output");
		//output 	= getDirectory("choose output directory");
	} else {
		showStatus("STEP I / III: processed 8-/16-bit input");
		orgdir	= getDirectory("choose input directory: 8-/16-bit image data");
	  	orgdirlist = getFileList(orgdir);
	  	showStatus("STEP I / III: binary input");
		bindir	= getDirectory("choose input directory: segmented binary");
	  	bindirlist = getFileList(bindir);
	  	showStatus("STEP I / III: output");
		output 	= getDirectory("choose output directory");}
			selectWindow(header);
			run("Close");
			// get dimensions of first original file
			run("Bio-Formats Macro Extensions");
			id = orgdir+orgdirlist[0]; // get ID of first element of org.filelist(ofl)
			Ext.setId(id);
			Ext.getSeriesName(seriesName);
			Ext.getImageCreationDate(creationDate);
  			Ext.getPixelsPhysicalSizeX(sizeX);
  			Ext.getPixelsPhysicalSizeY(sizeY);
  			Ext.getPixelsPhysicalSizeZ(sizeZ);
  			Ext.getPlaneTimingDeltaT(deltaT, 2);
  			Ext.getSizeC(sizeC);
// --- Variables and Identifiers Dialog Box ---
	guideII();
	showStatus("STEP II / III");
	Dialog.create(header+"- STEP II / III");
	Dialog.setLocation(DiaW,DiaH);
	Dialog.addMessage("DATE OF EXPERIMENT"); 
		//Dialog.addString("Name of Experiment:", seriesName, 15);
		Dialog.addNumber("Date of Experiment:", creationDate, 0, 8, "[yymmdd]");
		//Dialog.addNumber("Scale:", 3.8760, 4, 5, "  [px/µm]:");
	Dialog.addMessage("CHECK IMAGE DIMENSIONS")
		Dialog.addNumber("X-spacing:", sizeX, 2, 4, "  [µm]");
		Dialog.addNumber("Y-spacing:", sizeY, 2, 4, "  [µm]");
		Dialog.addNumber("Z-spacing:", sizeZ, 2, 4, "  [µm]");
		Dialog.addNumber("Time interval:", deltaT, 3, 4, "  [h]");
		//Dialog.addNumber("Channels:", sizeC, 0, 1, "#");
		//Dialog.addCheckbox("Count nuclei?", true);
	Dialog.addMessage("click -> OK <- to proceed to STEP 3/3\nclick 'HELP' for info");
		// Help Button see functions section
	//help();
		Dialog.show(); // show dialog before retrieving input
	date = d2s(Dialog.getNumber(), 0); // get first dialog input
	xs = Dialog.getNumber(); // get second dialog input
	ys = Dialog.getNumber(); // get fthird dialog input
	zs = Dialog.getNumber(); // get fourth dialog input
	time = Dialog.getNumber(); // get fifth dialog input
	nuc = Dialog.getChoice();
	// --- Genotype Input Dialog box ---
	showStatus("STEP III / III");
	selectWindow(header);
	run("Close");
	pos = newArray(orgdirlist.length);  // First, create empty array "pos" to be filled with Positional identifiers
	eTime = orgdirlist.length*2.5;
	guideIII();
	Dialog.create(header+"- STEP III / III");
	Dialog.setLocation(DiaW,DiaH);
	Dialog.addMessage("Define genotypes");
	for (j = 0; j < orgdirlist.length; j++){
		pos[j] = j;
		//d = pos[j];
		c = pos[j]+1;
		//print(c);
			if (j<9) { // because j starts from zero
			Dialog.addString("Position "+d2s(0,0)+d2s(c,0), "??", 6);
			} else {Dialog.addString("Position "+d2s(c,0), "??", 6);}
	}
	Dialog.addMessage("       ------------------------------------\n \nclick 'OK' to finish input and start macro\n \n       ------------------------------------");
	//Dialog.addMessage("Estimated duration: "+eTime+" min.");
		Dialog.show();
	selectWindow(header);
	run("Close");
		
// ##########################################################################################################################
// #################################################  PREPROCESSING #########################################################
// ##########################################################################################################################

// create empty arrays
	types = newArray(orgdirlist.length);
	embryoIDs = newArray(orgdirlist.length);
	embryodirs = newArray(orgdirlist.length);

if (pre) {
	for (q = 0; q < orgdirlist.length; q++) {
		setBatchMode(true);
		T1 = getTime();
		roiManager("reset");
	// 	Define and variables
			posi = pos[q]+1;
			if (posi<10) {position=d2s(0,0)+d2s(posi,0);}else{position=d2s(posi,0);}
			type = Dialog.getString(); // gets the genotype in every subsequent loop
			types[q] = type;
			embryoID = date + "." + position;
			embryoIDs[q] = embryoID;
	//	open [q] list element
	//	print processing process to log window
		if(q==0) {print("START PRE-PROCESSING ORIGINAL FILES");}
		if(q>0) {print(" ");}
		print("------------------------ processing Embryo ID: " + embryoID + " ------------------------");
	//	open first file out of orgdir
		open(orgdir+orgdirlist[q]);
		//wait(200);
		ORG = getTitle();
		selectWindow(ORG);
		//resetMinAndMax();
		run("Flip Horizontally", "stack");
		n = nSlices();
		setSlice(n);
	//	GET AVERAGE BACKGROUND VALUE
		run("Z Project...", "projection=[Average Intensity]");
		ZP = getTitle();
		selectWindow(ZP);
		//run("Enhance Contrast", "saturated=0.35"); // B&C Auto
		getDimensions(width, height, channels, slices, frames);
			makeRectangle(0, 0, width, height);
			List.setMeasurements;
  		BG = List.getValue("Mean");
		close(ZP); // closes Z-project
	//	BLEACH CORRECTION
		selectWindow(ORG);
		//run("Subtract...", "value=[BG] stack");
		print("Bleach correction...");
		run("Bleach Correction", "correction=[Simple Ratio] background=&BG");
		BC = getTitle();
	//	Morphological closing
		//run("Morphological Filters (3D)", "operation=Closing element=Ball x-radius=5 y-radius=5 z-radius=0");
		print("Morphological closing...");
		run("Morphological Filters (3D)", "operation=Closing element=Ball x-radius=5 y-radius=5 z-radius=0");
		MC = getTitle();
		close(BC);
	//	########################## BLURRING ##############################
		print("Blurring...");
		run("Gaussian Blur...", "sigma=5 scaled stack"); // MC
	//	get rotational angle and rotate
		print("Registering Lateral Line... (rotation and cropping)");
		selectWindow(MC);
		setSlice(n);
		run("Duplicate...", " ");
		Deg = getTitle();
			setAutoThreshold("Minimum dark");
			run("Convert to Mask");
		//run("Analyze Particles...", "size=150-Infinity exclude include add");
				run("Analyze Particles...", "size=150-Infinity add");
		//selectWindow(MC);
			rmcount = roiManager("count")-1;
		roiManager("select", 0);
		List.setMeasurements;
			X1Line = List.getValue("X");
			Y1Line = List.getValue("Y");
		roiManager("select", rmcount);
		List.setMeasurements;
			X2Line = List.getValue("X");
			Y2Line = List.getValue("Y");
		makeLine(X1Line, Y1Line, X2Line, Y2Line); 
		//roiManager("add");
		List.setMeasurements;
			Angle = List.getValue("Angle");
			if (Angle < -90) {Angle = Angle+180;}
			if (Angle > 90) {Angle = 180-Angle;}
			//Angle = Angle*(-1);
			//waitForUser("Wait");
		selectWindow(MC);
		run("Rotate... ", "angle=Angle grid=1 interpolation=Bilinear stack");
	//	get dimensions and crop
		selectWindow(Deg);
		getDimensions(width, height, channels, slices, frames);
		height = 450; // change height of rect here
		List.setMeasurements;
			YRect = List.getValue("Y");
			toUnscaled(YRect);
			YRect = YRect-(height/2);
		run("Analyze Particles...", "size=150-Infinity exclude include add");
			roiManager("select", 0);
		close(Deg);
		reset(); // function
	// Process binary
	selectWindow(MC);
		makeRectangle(0, YRect, width, height);
		run("Crop");
	resetThreshold(); //Thresholding
	setSlice(n);
	run("Convert to Mask", "method=Otsu dark background=Default");
	saveAs("Tiff", bindir + embryoID + "_RC_bin.tif");
	close(); // close BIN
	// Process ORG
	selectWindow(ORG);
		run("Rotate... ", "angle=Angle grid=1 interpolation=Bilinear stack");
		makeRectangle(0, YRect, width, height);
		run("Crop");
	saveAs("Tiff", rcdir + embryoID + "_RC.tif");
	//	#########     SEGMENTATION OF RC ORG	##############
	//run("Subtract...", "value=[BG] stack");
		print("Bleach correction...");
		run("Bleach Correction", "correction=[Simple Ratio] background=&BG");
		BC = getTitle();
	//	Morphological closing
		//run("Morphological Filters (3D)", "operation=Closing element=Ball x-radius=5 y-radius=5 z-radius=0");
		print("Morphological closing...");
		run("Morphological Filters (3D)", "operation=Closing element=Ball x-radius=5 y-radius=5 z-radius=0");
		MC = getTitle();
		close(BC);
	//	########################## BLURRING ##############################
		print("Blurring...");
		run("Gaussian Blur...", "sigma=5 scaled stack"); // MC
	close(); // close ORG
	T2 = getTime();
	Tdiff = T2-T1;
	print("Duration: "+Tdiff+"ms");
	}
bindirlist = getFileList(bindir);
//Array.show(bindirlist);
rcdirlist = getFileList(rcdir);
//Array.show(rcdirlist);
closelog();
roiManager("reset");
setBatchMode(false);
}

// ##########################################################################################################################
// ####################################################  ANALYSIS ###########################################################
// ##########################################################################################################################
// ############################  ENTER 1st LOOP TO INCREMENT OVER EACH FILE OF INPUT FOLDERS ################################
	
	for (b = 0; b < orgdirlist.length; b++) {
		setBatchMode(true);
		// get genotypes and embryoIDs from arrays
		type = types[b];
		embryoID = embryoIDs[b];
		// create directories for single embryos to save results
		embryodir = output + File.separator + embryoID + File.separator;
		File.makeDirectory(embryodir);
		// print StatsLog descriptors
		if (b==0) {StatsLogInfo();}
		// print Embryo ID 
		print("¸.·´¯`·.¸><(((º> "+" ID: "+embryoID+" | GT: "+type+"  <º))><¸.·`¯´·.¸");
		// open and define binary
		open(bindir+bindirlist[b]);
		wait(200);
		  BIN = getTitle();
		// open and define orginal 
		open(rcdir+rcdirlist[b]);
		wait(200);
		  RC = getTitle();
			dotIndex = indexOf(RC, ".");
			title = substring(RC, 0, dotIndex);
// 	Create Orphan measuring Row
	makeOval(10, 10, 5, 5);
	roiManager("measure");
	roiManager("reset");
	
// #############################  ENTER 2nd LOOP TO INCREMENT OVER EACH SLICE OF THE TIME-SERIES ##############################
	selectWindow(BIN); 	 // select binary
		for (i=1 ; i<=nSlices(); i++) {
		s = nSlices();
		setSlice(i);
wait(200);
		run("Analyze Particles...", "size=150-Infinity pixel include add");
		// Loop though ROI List
		roiManager("show none"); // supress roimanager popping up
		//run("Select None");
			for (j=0 ; j<roiManager("count"); j++) {
				roiManager("select", j);
				run("Set Scale...", "distance=1 known=0.00005 pixel=1 unit=micron");
				List.setMeasurements;
  				//print(List.getList); // list all measurements
  				x = List.getValue("X");
				//run("Set Scale...", "distance=1 known=0.005270 pixel=1 unit=micron");
    			roiManager("rename", x);
				}
		// Sort ROIs and select last one
		roiManager("Sort");
		//waitForUser("WAIT 300");
		//selectWindow(ORG);
		run("Properties...", "channels=1 slices=1 frames=[s] unit=micron pixel_width=[xs] pixel_height=[ys] voxel_depth=[zs] frame=[time] global");
		//run("Set Scale...", "distance=[scale] known=1 pixel=1 unit=micron"); // Scale defined in first dialog box
		n = roiManager("count");
		m = n-1;
		//waitForUser("HAL");
			// select ORG, Duplicate most-right ROI
			selectWindow(RC);
			//waitForUser("WAIT 307");
			roiManager("show none"); // supress roimanager popping up
				roiManager("Select", m);
				run("Enlarge...", "enlarge=5");
				run("Duplicate...", "use");
				resetMinAndMax();
				// Rotate
				List.setMeasurements;
					A = List.getValue("Angle");
					run("Select None");
						if (A < 10) {
							run("Rotate... ", "angle=[A] grid=1 interpolation=Bilinear slice");
						} else {
							A = 180-A;
							A = A*(-1);
							run("Rotate... ", "angle=[A] grid=1 interpolation=Bilinear slice"); }
				run("Flip Horizontally");
			selectWindow(RC); // select & deselect to remove selected ROIs
				run("Select None");
			// 	Measure and save segmented Mask ROI
				// create directory for ROIs
					embryorois = embryodir + File.separator + "ROIs" + File.separator;
					embryodirs[b] = embryodir;
					File.makeDirectory(embryorois);
wait(200);
			selectWindow(BIN);
			roiManager("show none"); // supress roimanager popping up
				roiManager("Select", m);
				roiManager("save selected", embryorois + "_s" + i + ".zip");
				run("Set Measurements...", "area centroid bounding fit shape feret's stack redirect=None decimal=2");
				//run("Extended Particle Analyzer", "pixel show=Masks redirect=None keep=None display");
    			roiManager("measure");
    			roiManager("reset");
    			run("Select None");
    		//  Calculate additional variables based on measurements
    		    n = nResults();
    		    r = n-1;  // actual RowNumber
    		    r2 = n-2; // RowNumber -1
    				if (i == 1) {  // get X & Y coordinates, keep X0 and Y0 for normalization
    					X0 = getResult("X");
    					Y0 = getResult("Y");
    				} else {
    					X1 = getResult("X", r2);
    					X2 = getResult("X", r);
    					Y1 = getResult("Y", r2);
    					Y2 = getResult("Y", r); }
    			// get width of bounding rectangle
    				W = getResult("Width");
    				// calculations (XN = normalized X; LE = Leading Edge)
    					// Euclidian Distance of X + normalized to offspring 'zero'
    					if (i == 1) {
    						XED = 0;
    						XN = 0;
    					} else {
    						XED = sqrt((X2-X1)*(X2-X1)+(Y2-Y1)*(Y2-Y1));
    						XN = (X2 - X0) + XED; }
    					LE = XN + (W/2); // Leading Edge 
    					T = time * r; // Time interval
    				setResult("Embryo", r, embryoID); // set Results
    				setResult("GT", r, type);
    				setResult("Time", r, T);
    				setResult("Deg", r, A);
    				setResult("X_ED", r, XED);
    				setResult("X_N", r, XN);
    				setResult("LE", r, LE);
    			updateResults();
    			// Velocitiy LE (LE1 = LE @ timepoint 1; LEN = normalized value of LE, LENV = Velocity of the normalized value of LE)
    				if (i == 1) {
    						LE1 = LE; // LE1 will be the same for all further timepoints
    						LEN = 0; //
    						LENED = NaN; // 'Leading Edge Normalized Euclidian Distance'
    						LEV = NaN; // For the first timepoint there can be no speed, since there was no coordinate of X and Y before
    					} else {
    						LEN = LE - LE1; // The value of 'LE Normalized' to zero 
    						LED = getResult("LE_N", r2); // LED = The value of LE one row before
    						LENED = sqrt((LEN-LED)*(LEN-LED)+(Y2-Y1)*(Y2-Y1)); // LENED = LEN - (LEN-LED);
    						LEV = LENED / time;
    						}
    				setResult("LE_N", r, LEN); // setResult Leading Edge Normalized (LE_N)
    			    setResult("LE_N_ED", r, LENED); // setResult Leading Edge Normalized Euclidian Distance (LE_N_ED)
    			    setResult("LE_V", r, LEV); // setResult Leading Edge Velocity (LE_V)
    			updateResults();
    			//waitForUser("391");
			}
		close(BIN); // could be reduced to close(BIN, ORG); or close (".tif");
		close(RC);
		setBatchMode("exit and display");
			run("Images to Stack", "method=[Copy (top-left)] name=Stack title=[] use");
	//run("Images to Stack", "method=[Scale (smallest)] name=Stack title=[] use");
		run("Flip Horizontally", "stack");
		saveAs("Tiff", pLLPdir + embryoID + "_pLLP.tif");
		close();
	// Save Results Table
		run("Input/Output...", "jpeg=100 gif=-1 file=.txt use_file copy_column copy_row save_column");
		saveAs("results", embryodir + embryoID + "_Results" + ".txt");
		//if (i==1){
		//	String.copyResults();
		//} else {String.append(String.copyResults());}
	// Calulate Stats and show in Log
		StatsLog();
	// Correlate Results
		print("------------------------ LM Fit ------------------------");
		run("Correlate Results", "x=Time y=LE_N equation=[Straight Line] show graph=Circles");
		saveAs("Tiff", embryodir + embryoID + "_ScatterPlot");
		close();
		//IJ.renameResults("Results");
		cleanup();
	}
	
// ################################ POSTPROCESSING #########################################

// Save statistics from log file
	selectWindow("Log");
	saveAs("Text", output + date + "_Stats" + ".txt");
	closelog();
	//getrois();
	print("Merging result tables, check main window to track progress...");
	boxplot();
	updateResults();
	combRes = output + File.separator + date + "_CombinedResults.txt" + File.separator;
	saveAs("results", output + date + "_CombinedResults" + ".txt");
	cleanup();
	run("Create Boxplot", "use=[External file...] open=combRes round group=GT");
		wait(350);
		run("Capture Screen");
		makeRectangle(810, 219, 300, 392);
		run("Crop");
		saveAs("Tiff", output + date + "_BoxRound");
		run("Close");
	run("Create Boxplot", "use=[] area group=GT");
		wait(350);
		run("Capture Screen");
		makeRectangle(810, 219, 300, 392);
		run("Crop");
		saveAs("Tiff", output + date + "_Area");
		run("Close");
	run("Create Boxplot", "use=[] le_v group=GT");
		wait(350);
		run("Capture Screen");
		makeRectangle(810, 219, 300, 392);
		run("Crop");
		saveAs("Tiff", output + date + "_BoxSpeed");
		run("Close");
		wait(200);
	closelog();
		wait(200);
	IJ.renameResults("Results"); // renames imported external results table to 'Results' to close it again
	cleanup();
	if(getBoolean("DONE! :).\nOpen output directory?"))
    call("bar.Utils.revealFile", output);
    print("Registered pLLPs can be found under...\n"+pLLPdir);

// ============================================================================================================================
// ######################################### FUNCTIONS ########################################################################
// ============================================================================================================================
function cleanup(){
		if (isOpen("Results")) { 
		selectWindow("Results"); 
		run("Close");} 
		if (isOpen("ROI Manager")){
		selectWindow("ROI Manager");
		run("Close");}
	run("Close All");
}

function roireset(){
	roiManager("reset");
	run("Select None");
}

function closelog() {
if (isOpen("Log")) { 
    selectWindow("Log"); 
    run("Close"); 
}}

function StatsLogInfo() {
	print("======================== STATS ========================");
	print("[N] = number of datapoints");
	print("[Mean] = Added values / number of datapoints");
	print("[Var] = Variance = sigma^2 = E[(x-µ)^2]");
	print("[SD] = Standard Deviation = sigma = sqrt(E[X^2]-(E[X])^2)");
	print("[SE] = Standard Error = sigma/sqrt(n)");
	print("[95% CI] = Confidence Interval = 0.196*SE");
	print("[LM Fit] = Linear regression fitted model");
print("=======================================================");
}

function StatsLog() { // Richard Mort 13/04/2012:http://imagejdocu.tudor.lu/doku.php?id=macro:calculating_stats_from_a_results_table
		// Area STATS
		for (a = 0; a < nResults(); a++) {
    		total_area = total_area + getResult("Area", a);
    		mean_area = total_area / nResults;
			}
			for (a = 0; a < nResults(); a++) {
    		total_variance_Area = total_variance_Area + (getResult("Area",a)-(mean_area))*(getResult("Area",a)-(mean_area));
    		variance_area = total_variance_Area/(nResults-1);
			}
			SD_Area = sqrt(variance_area); // SD, SE and CI of "Area" column (note: requires variance)
			SE_Area = (SD_Area/(sqrt(n)));
			CI95_Area = 1.96*SE_Area;
		// Roundness STATS
			for (a = 0; a < n; a++) {
    			total_round = total_round + getResult("Round", a);
   				mean_round = total_round / n;
				}
			for (a = 0; a < n; a++) {
    			total_variance_round = total_variance_round + (getResult("Round",a)-(mean_round))*(getResult("Round",a)-(mean_round));
    			variance_round = total_variance_round/(n-1);
				}
			SD_Round = sqrt(variance_round); // SD of "Round" column (note: requires variance)
			SE_Round = (SD_Round/(sqrt(n)));
			CI95_Round = 1.96*SE_Round;
		// LE STATS
			for (a = 1; a < nResults(); a++) {
    			total_V = total_V + getResult("LE_V", a);
    			mean_V = total_V/nResults;
				}
			for (a = 1; a < nResults(); a++) {
    			total_variance = total_variance + (getResult("LE_V", a)-(mean_V))*(getResult("LE_V", a)-(mean_V));
    			variance_V = total_variance / (nResults-1);
				}
			nV = n-1;
			SD_V = sqrt(variance_V); // SD of "LE_V" column (note: requires variance)
			SE_V = (SD_V/(sqrt(nV)));
			CI95_V = 1.96*SE_V;
// Print stats
print("------------------------ AREA -------------------------");
	print("[N] Datapoints = "+ n);
	print("Mean Area = "+ mean_area + " [µm^2]");
	print("Var Area = "+ variance_area);
	print("SD Area = "+ SD_Area);
	print("SE Area = "+ SE_Area);
	print("95% CI Area = "+ CI95_Area);
print("---------------------- ROUNDNESS ----------------------");
	print("[N] Datapoints = "+ n);
	print("Mean Roundness = "+ mean_round + " [inv.AR]");
	print("Var Roundness = "+ variance_round);
	print("SD Roundness = "+ SD_Round);
	print("SE Roundness = "+ SE_Round);
	print("95% CI Roundness = "+ CI95_Round);
print("---------------------- VELOCITY -----------------------");
	print("[N] Datapoints = "+ nV);
	print("Mean Velocity = "+ mean_V + " [µm/h]");
	print("Var Velocity = "+ variance_V);
	print("SD Velocity = "+ SD_V);
	print("SE Velocity = "+ SE_V);
	print("95% CI Velocity = "+ CI95_V);
}

function help() {
				html = "<html>"
			+"<h1><font color=purple>pLLP ANALYZER v0.6 INFO log</h1>"
     		+"<h><b>Date</b></h>"
     			+"Please enter the date in the format <b>'yymmdd'</b> for later identification.<br>"
     		+"<h><b>Position</b></h>"
     			+"Please enter the embryos positional ID in the format <b>'nn'</b>, like 01, 02, ....<br>"
     		+"<h><b>Scale</b></h>"
     			+"Please enter the spatial calibration in <b>Pixels / micron</b>.<br>"
     		+"<h><b>Time</b></h>"
     		     +"Please enter the time interval in <b>hours</b>.<br>"
     		+"<h><b>Genotype</b></h>"
     			+"Please enter a <b>genotype without semicolon or slashes<b>.<br>"
     		+"<h><b>Nuclei counting</b></h>"
     			+"If the Image Data contains a second channel with a Nuclei Label, you can check the box to have the nuclei counted as well.<br>"
     		+"<h><b>Pre-processing</b></h>"
     			+"If the Image Data contains a second channel with a Nuclei Label, you can check the box to have the nuclei counted as well.<br>"
     		+"<h1><u><small>contact<small></u></h1>"
     		+"<small>David Kleinhans, AK Lecaudey, GU FFM, 11/16.<small><br>"
     		//Dialog.create("Help");
     		Dialog.addHelp(html);
}

function info() {
				html = "<html>"
			+"<h1><font color=purple>pLLP ANALYZER v0.6 INFO log</h1>"
     		+"<h1><b>RESULT TABLES</b></h1>"
     		+"<h><b>Measurements</b><h>"
     		 +"<ul>"
     			+"<li> Area<br>"
     			+"<li> Centroid [X/Y]<br>"
     			+"<li> Bounding Rectangle [BX/BY/Width/Height]<br>"
     			+"<li> Ellipsoid fit<br>"
     			+"<li> Angle<br>"
     			+"<li> Shape Discriptors<br>"
     			+"<li> Ferret's diameter<br>"
     			+"<li> Stack position [Slice number]<br>"
     			+"<li> Aspect Ratio [AR]<br>"
     			+"<li> Roundness [inv.AR]<br>"
     			+"<li> Solidity<br>"
     		 +"</ul>"
     		+"<h><b>Identifiers</b><h>"
     		 +"<ul>"
     			+"<li> Embryo [yymmdd.nn]<br>"
     			+"<li> Genotype [++ +- --]<br>"
     		 +"</ul>"
     		+"<h><b>Calculated variables</b><h>"
     		 +"<ul>"
     		     +"<li> Time [Slice x Time interval]<br>"
     		     +"<li> X_ED [X corrected by euclidian distance measurement]<br>"
     		     +"<li> X_N [X_ED normalized to T1]<br>"
     		     +"<li> LE [X_N + Width/2]<br>"
     		     +"<li> LE_N [LE normalized to T1]<br>"
     		     +"<li> LE_N_ED [LE_N corrected by euclidian distance measurement]<br>"
     		     +"<li> LE_V [LE_N_ED / Time interval]<br>"
     		 +"</ul>"
     		+"<h><b>Nuclei counting</b></h>"
     		 +"<ul>"
     			+"<li>Nuclei are counted based on max-projected Z-stacks with a nuclei label (e.g. H2B:RFP).<br>"
     		 +"</ul>"
     			 +"<ol>"
     				+"<li>First, the nuclei are blurred according to the average nuclei width in µm<br>"
     				+"<li>Then, the maxima finder is used to detect the peaks of the signal.<br>"
     			 +"</ol>"
     		+"<h1><b>REGISTERED pLLP</b></h1>"
     		+"<h1><b>STATS</b></h1>"
     		+"<h1><b>PLOTS</b></h1>"
     		+"<h1><u><small>contact<small></u></h1>"
     		+"<small>David Kleinhans, AK Lecaudey, GU FFM, 11/16.<small><br>"
     		Dialog.addHelp(html);
}

function boxplot() {
	for (e = 0; e < rcdirlist.length; e++) {
		showProgress(-e, rcdirlist.length);
		setBatchMode(true);
		// get genotypes and embryoIDs from arrays
			type = types[e];
			embryoID = embryoIDs[e];
		print("Collecting data for: " + embryoID);
		//if (e==0) {StatsLogInfo();}
		open(bindir+bindirlist[e]);
		  BIN = getTitle();
		open(rcdir+rcdirlist[e]);
		  RC = getTitle();
			dotIndex = indexOf(RC, ".");
			title = substring(RC, 0, dotIndex);
	makeOval(10, 10, 5, 5);
	roiManager("measure");
	roiManager("reset");
// ############################  ENTER 2nd LOOP TO INCREMENT OVER EACH SLICE OF THE TIME-SERIES ################################

	selectImage(BIN); // select binary
		for (f=1 ; f<=nSlices(); f++) {
		s = nSlices();
		setSlice(f);
		run("Analyze Particles...", "size=150-Infinity pixel include add");
		//roiManager("show none"); // supress roimanager popping up
			for (p=0 ; p<roiManager("count"); p++) { // Loop though ROI List
				roiManager("select", p);
				run("Set Scale...", "distance=1 known=0.00005 pixel=1 unit=micron");
				List.setMeasurements;
  				x = List.getValue("X");
    			roiManager("rename", x);
				}
		roiManager("Sort");
//waitForUser("666 Check Roi manager");
		n = roiManager("count");
		m = n-1;
			selectImage(BIN);
			roiManager("Show None"); // supress roimanager popping up
//waitForUser("671 Check Roi manager");
				roiManager("Select", m);
				run("Properties...", "channels=1 slices=1 frames=[s] unit=micron pixel_width=[xs] pixel_height=[ys] voxel_depth=[zs] frame=[time] global");
				run("Set Measurements...", "area centroid bounding fit shape feret's stack display redirect=None decimal=2");
				//run("Extended Particle Analyzer", "pixel show=Masks redirect=None keep=None display");
    			roiManager("measure");
    			roiManager("reset");
    			run("Select None");
    		//  Calculate additional variables based on measurements
    		    n = nResults();
    		    r = n-1;  // actual RowNumber
    		    r2 = n-2; // RowNumber -1
    				if (f == 1) {  // get X & Y coordinates, keep X0 and Y0 for normalization
    					X0 = getResult("X");
    					Y0 = getResult("Y");
    				} else {
    					X1 = getResult("X", r2);
    					X2 = getResult("X", r);
    					Y1 = getResult("Y", r2);
    					Y2 = getResult("Y", r); }
    			// get width of bounding rectangle
    				W = getResult("Width");
    				// calculations (XN = normalized X; LE = Leading Edge)
    					// Euclidian Distance of X + normalized to offspring 'zero'
    					if (f == 1) {
    						XED = 0;
    						XN = 0;
    					} else {
    						XED = sqrt((X2-X1)*(X2-X1)+(Y2-Y1)*(Y2-Y1));
    						XN = (X2 - X0) + XED; }
    					LE = XN + (W/2); // Leading Edge 
    					T = time * r; // Time interval
    				setResult("Embryo", r, embryoID); // set Results
    				setResult("GT", r, type);
    				setResult("Time", r, T);
    				setResult("Deg", r, A);
    				setResult("X_ED", r, XED);
    				setResult("X_N", r, XN);
    				setResult("LE", r, LE);
    			updateResults();
    			// Velocitiy LE (LE1 = LE @ timepoint 1; LEN = normalized value of LE, LENV = Velocity of the normalized value of LE)
    				if (f == 1) {
    						LE1 = LE; // LE1 will be the same for all further timepoints
    						LEN = 0; //
    						LENED = NaN; // 'Leading Edge Normalized Euclidian Distance'
    						LEV = NaN; // For the first timepoint there can be no speed, since there was no coordinate of X and Y before
    					} else {
    						LEN = LE - LE1; // The value of 'LE Normalized' to zero 
    						LED = getResult("LE_N", r2); // LED = The value of LE one row before
    						LENED = sqrt((LEN-LED)*(LEN-LED)+(Y2-Y1)*(Y2-Y1)); // LENED = LEN - (LEN-LED);
    						LEV = LENED / time;
    						}
    				setResult("LE_N", r, LEN); // setResult Leading Edge Normalized (LE_N)
    			    setResult("LE_N_ED", r, LENED); // setResult Leading Edge Normalized Euclidian Distance (LE_N_ED)
    			    setResult("LE_V", r, LEV); // setResult Leading Edge Velocity (LE_V)
    			updateResults();
			}
		close(BIN); // could be reduced to close(BIN, ORG); or close (".tif");
		close(RC);
	}
	print("Done. Saving "+ date + "_CombinedResults.txt" );
}

function guideI () {
	newImage(header, "8-bit black", 350, 490, 1);
	setLocation(InfoW, InfoH)
	setColor(200, 200, 200);
  	setFont("SansSerif", 20, "antiliased bold");
  	drawString("STEP I / III\n ", 10, 35);
  	setFont("SansSerif", 20, "antiliased");
  	setColor(255, 255, 255);
  	drawString(" \nPlease select your kind of input data\n \n1. RAW data is already stitched\nand Z-projected.\n \n2. Pre-processed data is, in addition, \nalready rotated and cropped to the \nmargins of the lateral line \n(as 8- /16-bit and binary).", 10, 60);
}

function guideI2 () {
	newImage(header, "8-bit black", 350, 150, 1);
	setLocation(DiaW, DiaH);
  	setFont("SansSerif", 18, "antiliased");
  	setColor(255, 255, 255);
  	drawString("Please select your input directory, \nwhich is, where the data is stored \nthat should be processed.", 10, 30);
}

function guideII () {
	newImage(header, "8-bit black", 350, 490, 1);
	setLocation(InfoW, InfoH);
	setColor(200, 200, 200);
  	setFont("SansSerif", 20, "antiliased bold");
  	drawString("STEP II / III\n ", 10, 35);
  	setFont("SansSerif", 18, "antiliased");
  	setColor(255, 255, 255);
  	drawString(" \nTo add identifiers to your result tables, \nplease enter the date of the \nexperiment in [yymmdd]. \nAlso, please check the dimension \nproperties, as this is the calibration\ninformation based on which your \ndata willbe analyzed. \n \nCorrect them if necessary. \n \nThe time interval is needed to \ncalculate the developmental stage \nat each frame..", 10, 60);
}

function guideIII () {
	newImage(header, "8-bit rgb black", 350, 490, 1);
	setLocation(InfoW, InfoH);
	setColor(200, 200, 200);
  	setFont("SansSerif", 20, "antiliased bold");
  	drawString("STEP III / III\n ", 10, 35);
  	setFont("SansSerif", 18, "antiliased");
  	setColor(255, 255, 255);
  	drawString(" \nPlease enter your genotypes \n \nthis will be necessary to \ngroup your data in subsequent \ndata analysis. \n \nIt might look like...\n++ or\n++ -- or\n++ -- ++ or even \nbla++ bla-- bla++\n \njust be consistent!\n-----------\nEstimated duration:", 10, 60);
	setFont("SansSerif", 25, "antiliased bold");
	setColor(0, 200, 0);
	drawString(eTime+" min.", 10, 460);
}

function getrois() {
	outputlist = getFileList(output);
		for (v = 0; v < outputlist.length; v++) {
			embryodir = embryodirs[v]; // From filled array edirs
			embryodirlist = getFileList(embryodir);
			for (w = 0; w < embryodirlist.length; w++) {
				rois = getFileList(embryodirlist[w]);
					for (y = 0; y < rois.length; y++) {
						roiManager("open", rois[y]);
						//run("Set Measurements...", "area centroid bounding fit shape feret's stack redirect=None decimal=2");
						//run("measure");
					}
				roiManager("save", embryodir + "ROIs.zip");
			}
		}
}
