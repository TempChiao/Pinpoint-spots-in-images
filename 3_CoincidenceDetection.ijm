// Purpose - detect number, intensity and size of protein species on a pull-down surface and compute real/chance signal coincidence between channels


// USER INPUTS ///////////////////////////////////////////////

greenID = "AF568-trans.tif"; // Provide filename suffix for green channel images
redID = "NR.tif"; // Provide filename suffix for red channel images

// Max projection of frames used for analysis, define here the number of frames to include
stopSlice = 20; 

// Set threshold particle size (number of pixels) for species detection
green_particlesize = 4;
red_particlesize = 4;

// Set threshold intensity (SD above mean of ComDet-filtered image) for species detection
green_threshold = 5;
red_threshold = 5;

// Set allowable distance between colocal events (in pixels)
dist = 2; 





// MAIN CODE ////////////////////////////////////////////////

// Set up working environment
setBatchMode("hide");
run("Clear Results");

// Prompt user to provide select data folder (which contains subfolders per condition within which are all FOVs, channels are in separate files)
dir = getDir("Indicate overarching results folder to process");

// Create list of all subfolders
folderList = getFileList(dir);

//Create save directory
File.makeDirectory(dir + "Analysis/");

// For each subfolder
for (i = 0; i < lengthOf(folderList); i++) {
	
	if (folderList[i] != "Analysis/") {	
		// Create matching save subdirectory
		File.makeDirectory(dir + "Analysis/" + folderList[i]);
		
		// Count FOV number in current directory
		fileList = getFileList(dir + folderList[i]);
		
		FOV_num = 0;
		for (j = 0; j < lengthOf(fileList); j++) {
			if (endsWith(fileList[j], greenID)) {
				FOV_num = FOV_num + 1;
			}
		}		
		
		filePrefix = substring(fileList[0], 0, indexOf(fileList[0], "_posXY") + 6);
		fileSuffix = substring(fileList[0], indexOf(fileList[0], "_channels"), indexOf(fileList[0], greenID));
	
		// For each FOV within the folder (excluding the results folder)
		for (j = 0; j < FOV_num; j++) {
		
				
			// Open each channel and Z-project		
			run("Bio-Formats Importer", "open=[" + dir + folderList[i] + filePrefix + j + fileSuffix + greenID + "] color_mode=Default rois_import=[ROI manager] view=Hyperstack stack_order=XYCZT");
			rename("green");
			run("Z Project...", "stop=" + stopSlice +" projection=[Max Intensity]");
			close("green");
			
			run("Bio-Formats Importer", "open=[" + dir + folderList[i] + filePrefix + j + fileSuffix + redID + "] color_mode=Default rois_import=[ROI manager] view=Hyperstack stack_order=XYCZT");
	   		rename("red");
	   		run("Z Project...", "stop=" + stopSlice +" projection=[Max Intensity]");
	   		close("red");
			
			// Create channel duplicates and transform one with respect to the other as a control for chance coincidence
			selectWindow("MAX_green");
			run("Duplicate...", "title=MAX_green_transform duplicate");
			selectWindow("MAX_red");
	   		run("Duplicate...", "title=MAX_red_transform duplicate");
			run("Flip Horizontally");
			run("Flip Vertically");
	
			// Merge and rename channels
	   		run("Merge Channels...", "c1=MAX_red c2=MAX_green create");
	   		rename("test");
	   		run("Merge Channels...", "c1=MAX_red_transform c2=MAX_green_transform create");
	   		rename("transform");

	   		// For test case, detect particles and compute intensity, size and channel coincidence using the ComDet plug-in
	   		selectWindow("test");
	   		run("Detect Particles", "calculate max=" + dist + " plot rois=Ovals add=Nothing summary=Reset ch1i ch1a=" + red_particlesize + " ch1s=" + red_threshold + " ch2i ch2a=" + green_particlesize + " ch2s=" + green_threshold); 
			
			// Save results and close results windows
			selectWindow("test");
			saveAs("Tiff", "" + dir + "Analysis/" + folderList[i] + "posXY" + j + "_Test-Results.tif"); // This file contains the image file with detected particles indicated in overlay
			close("posXY" + j + "_Test-Results.tif");
			
			selectWindow("Results");
			saveAs("Results", dir + "Analysis/" + folderList[i] + "posXY" + j + "_descriptors.csv"); // This file contains intensity/size descriptors of all detections
			close("posXY" + j + "_descriptors.csv");
			
			selectWindow("Summary");
			saveAs("Results", dir + "Analysis/" + folderList[i] + "posXY" + j + "_Test-Results.csv"); // This file contains the total number of particles detected and the channel coincidence
			close("posXY" + j + "_Test-Results.csv");
			
			run("Clear Results");

			// For transform control, detect particles and compute channel coincidence using the ComDet plug-in
			selectWindow("transform");
	   		run("Detect Particles", "calculate max=" + dist + " plot rois=Ovals add=Nothing summary=Reset ch1i ch1a=" + red_particlesize + " ch1s=" + red_threshold + " ch2i ch2a=" + green_particlesize + " ch2s=" + green_threshold); 
			
			// Save results and close results windows
			selectWindow("transform");
			saveAs("Tiff", "" + dir + "Analysis/" + folderList[i] + "posXY" + j + "_Transform-Results.tif"); // This file contains the image file with detected particles indicated in overlay
			close("posXY" + j + "_Transform-Results.tif");
			
			selectWindow("Summary");
			saveAs("Results", dir + "Analysis/" + folderList[i] + "posXY" + j + "_Transform-Results.csv"); // This file contains the total number of particles detected and the channel coincidence
			close("posXY" + j + "_Transform-Results.csv");
			
			run("Clear Results");
			run("Close All");
		}

	}

}

