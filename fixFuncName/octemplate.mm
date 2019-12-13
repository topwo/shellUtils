//---------------------------------------修改OC层函数名后，为了不改js层，添加的映射----------------------------------start
NSDictionary *funcname_dict = nil;
const char* fixFuncName(const char *func_name){
\\	if(!funcname_dict){
\\	\\	//读入文件
\\	\\	//NSString *jsonDict = [[NSBundle mainBundle] pathForResource:@"funcname" ofType:@".json"];
\\	\\	//NSString *content = [NSString stringWithContentsOfFile:jsonDict encoding:NSUTF8StringEncoding error:nil];
\\	\\	//NSLog(@"%@",content);   //这句话可以用来测试是否读取到数据
\\	\\	NSString *class_method_str = @"{}";
\\	\\	//转换成二进制数据
\\	\\	NSData * data = [class_method_str dataUsingEncoding:NSUTF8StringEncoding];
\\	\\	//解析JSON文件 OC中自带的方法
\\	\\	funcname_dict = [[NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:nil] retain];
\\	}
\\	NSString *old_func_name = [NSString stringWithUTF8String:func_name];
\\	NSString *new_func_name = [funcname_dict objectForKey:old_func_name];
\\	if(new_func_name){
\\	\\	return [new_func_name UTF8String];
\\	}

\\	if([old_func_name hasSuffix:@":"]){
\\	\\	NSString * sub_old_func_name = [old_func_name substringToIndex:[old_func_name length] - 1];
\\	\\	new_func_name = [funcname_dict objectForKey:sub_old_func_name];
\\	\\	if(new_func_name){
\\	\\	\\	return [[new_func_name stringByAppendingString:@":"] UTF8String];
\\	\\	}
\\	}
\\	return func_name;
}
//---------------------------------------修改OC层函数名后，为了不改js层，添加的映射----------------------------------end

