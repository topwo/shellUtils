require 'optparse'
require 'Xcodeproj'

def traverse_and_add_dir(target, parentGroup, fileName, filePath, fileReferences)
	if !(fileName =~ /^\./)
	    if File.directory? filePath
	    	xiGroup = parentGroup.find_subpath(File.join(fileName), true)
	    	# puts xiGroup
	    	xiGroup.clear
			xiGroup.set_source_tree('<group>')
			xiGroup.set_path(filePath)

	        Dir.foreach(filePath) do |file|
	            traverse_and_add_dir(target, xiGroup, file, filePath+"/"+file, fileReferences)
	        end
	    else
	        #puts "File:#{File.basename(file_path)}, Size:#{File.size(file_path)}"

	        file_ref = parentGroup.new_reference(filePath)
	        if !(fileName =~ /\.h$/)
	        	fileReferences.push(file_ref)
	        end
	    end
	else
		#puts "hide file:   [" + "#{fileName}" + "]"
	end
end

def editProj(projDir, project_path, xcodeTargetName, interNameOld, interNameNew)
	project = Xcodeproj::Project.open(project_path)

	targetIndex = 0
	project.targets.each_with_index do |target, index|
	  	if target.name == xcodeTargetName
	    	targetIndex = index
	  	end
	end
	target = project.targets[targetIndex]

	iosGroup = project.main_group["ios"]

	#删除老的接口目录引用
	# tmp_files = Array.new
	# target.source_build_phase.files.each do |file|
	# 	if file.file_ref.nil? || (file.file_ref.parent.display_name == "Recovered References") || (file.file_ref.parent.display_name == file.file_ref.display_name)
	# 		puts file.file_ref
	# 		tmp_files.push(file)
	# 	end
	# end
	# tmp_files.each do |file|
	# 	file.remove_from_project
	# end
	iosGroup.find_subpath(File.join(interNameOld), true).remove_from_project

	#创建新的接口目录引用
	fileReferences = Array.new
	traverse_and_add_dir(target, iosGroup, interNameNew, projDir + "/ios/" + interNameNew, fileReferences)
	target.add_file_references(fileReferences)

	# #TODO 如果太多后面就改成灵活方式
	# isARC = false
	# target.build_configurations.each do |config|
	# 	if config.name == "Release"
	# 		isARC = config.build_settings["CLANG_ENABLE_OBJC_ARC"]
	# 	end
	# end
	# puts "isARC" + isARC
	# if finalSDKs_has_100 == "true"
	# 	puts "finalSDKs_has_100" + finalSDKs_has_100
	# 	target.source_build_phase.files.each do |file| 
	# 		if (file.display_name == "IAPShare.m") || (file.display_name == "IAPHelper_.m") || (file.display_name == "InAppPay.m")
	# 			file.settings = Hash["COMPILER_FLAGS" =>  "-fobjc-arc"]
	# 		end
	# 	end
	# end
	# if shoumengType == "true"
	# 	target.source_build_phase.files.each do |file| 
	# 		if (file.display_name == newXIMain)
	# 			file.settings = Hash["COMPILER_FLAGS" =>  "-fno-objc-arc"]
	# 		end
	# 	end
	# end

	project.save

	return true
end

def removeUnuse(project_path, xcodeTargetName)
	project = Xcodeproj::Project.open(project_path)

	targetIndex = 0
	project.targets.each_with_index do |target, index|
	  	if target.name == xcodeTargetName
	    	targetIndex = index
	  	end
	end
	target = project.targets[targetIndex]

	#删除老的接口目录引用
	tmp_files = Array.new
	target.source_build_phase.files.each do |file|
		if file.file_ref.nil? || (file.file_ref.parent.display_name == "Recovered References") || (file.file_ref.parent.display_name == file.file_ref.display_name)
			puts file.file_ref
			tmp_files.push(file)
		end
	end
	tmp_files.each do |file|
		file.remove_from_project
	end

	recoveredGroup = project.main_group["Recovered References"]
	if recoveredGroup.nil? == false
		recoveredGroup.files.each do |file|
			file.remove_from_project
		end
		recoveredGroup.remove_from_project
	end

	project.save

	return true
end

def getBuildSetting(project_path, xcodeTargetName, file_path)
	project = Xcodeproj::Project.open(project_path)

	targetIndex = 0
	project.targets.each_with_index do |target, index|
	  	if target.name == xcodeTargetName
	    	targetIndex = index
	  	end
	end
	target = project.targets[targetIndex]
	target.source_build_phase.files.each do |file|
		if file.file_ref.real_path.to_s == file_path && file.settings.nil? == false && file.settings.empty? == false
			puts file.settings["COMPILER_FLAGS"]
			break
		end
	end
end

def setBuildSetting(project_path, xcodeTargetName, file_path, arc_setting)
	project = Xcodeproj::Project.open(project_path)

	targetIndex = 0
	project.targets.each_with_index do |target, index|
	  	if target.name == xcodeTargetName
	    	targetIndex = index
	  	end
	end
	target = project.targets[targetIndex]
	target.source_build_phase.files.each do |file|
		if file.file_ref.nil? == false && file.file_ref.real_path.nil? == false && file.file_ref.real_path.to_s == file_path && arc_setting.nil? == false && arc_setting.empty? == false && (arc_setting == "-fno-objc-arc" || arc_setting == "-fobjc-arc")
			puts "setBuildSetting file_path "+file_path+" "+arc_setting
			file.settings = Hash["COMPILER_FLAGS" => arc_setting]
			break
		end
	end
	project.save
end

if ARGV[0] == "editProj"
	editProj ARGV[1],ARGV[2],ARGV[3],ARGV[4],ARGV[5]
elsif ARGV[0] == "getBuildSetting"
	getBuildSetting ARGV[1],ARGV[2],ARGV[3]
elsif ARGV[0] == "setBuildSetting"
	setBuildSetting ARGV[1],ARGV[2],ARGV[3],ARGV[4]
elsif ARGV[0] == "removeUnuse"
	removeUnuse ARGV[1],ARGV[2]
end