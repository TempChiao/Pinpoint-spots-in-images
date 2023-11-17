// Purpose - detect number, intensity and size of protein species on a pull-down surface and compute real/chance signal coincidence between channels


// USER INPUTS ///////////////////////////////////////////////

chID = "AF568-trans.tif"; // Provide filename suffix for green channel images

// Max projection of frames used for analysis, define here the number of frames to include
stopSlice = 20; 

// Set threshold particle size (number of pixels) for species detection
particlesize = 4;

// Set threshold intensity (SD above mean of ComDet-filtered image) for species detection
threshold = 5;


crop_coords = newArray(0, 210, 428, 280);


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
			if (endsWith(fileList[j], chID)) {
				FOV_num = FOV_num + 1;
			}
		}		
		
		filePrefix = substring(fileList[0], 0, indexOf(fileList[0], "_posXY") + 6);
		fileSuffix = substring(fileList[0], indexOf(fileList[0], "_channels"), indexOf(fileList[0], chID));
	
		// For each FOV within the folder (excluding the results folder)
		for (j = 0; j < FOV_num; j++) {
		
				
			// Open each channel and Z-project		
			run("Bio-Formats Importer", "open=[" + dir + folderList[i] + filePrefix + j + fileSuffix + chID + "] color_mode=Default rois_import=[ROI manager] view=Hyperstack stack_order=XYCZT");
			rename("img");
			run("Z Project...", "stop=" + stopSlice +" projection=[Max Intensity]");
			close("img");

	   		// For test case, detect particles and compute intensity, size and channel coincidence using the ComDet plug-in
	   		selectWindow("MAX_img");
	   		
	   		makeRectangle(crop_coords[0],crop_coords[1],crop_coords[2],crop_coords[3]);
			run("Crop");

	   		run("Detect Particles", "ch1i ch1a=4 ch1s=5 rois=Ovals add=Nothing summary=Reset");
			
			// Save results and close results windows
			selectWindow("MAX_img");
			saveAs("Tiff", "" + dir + "Analysis/" + folderList[i] + "posXY" + j + "_ComDet-Results.tif"); // This file contains the image file with detected particles indicated in overlay
			close("posXY" + j + "_ComDet-Results.tif");
			
			selectWindow("Results");
			saveAs("Results", dir + "Analysis/" + folderList[i] + "posXY" + j + "_descriptors.csv"); // This file contains intensity/size descriptors of all detections
			close("posXY" + j + "_descriptors.csv");
			
			selectWindow("Summary");
			saveAs("Results", dir + "Analysis/" + folderList[i] + "posXY" + j + "_ComDet-Results.csv"); // This file contains the total number of particles detected and the channel coincidence
			close("posXY" + j + "_ComDet-Results.csv");
			
			run("Clear Results");
			run("Close All");
		}

	}

}

