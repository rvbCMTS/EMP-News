%% A script demonstrating how to work with databases in MATLAB 

% This MATLAB Classic script (m-file) is minimally commented. Please see 
% the Live Script (or its html output) for in-depth commenting and 
% explanation.
%
% This classic script accompanies the article "Hacking Medical Physics. 
% Part 2. Working with databases—a step beyond spreadsheets" published 
% in the Spring 2022 issue of European Medical Physics News.
%
% The script illustrates how to:
% * Connect to an SQLite database in MATLAB using the JDBC drivers (the 
% driver is in the lib-matlab subdirectory of this repository, i.e. 
% EMP-News/Part2/lib-matlab)
% * How to read Excel file data with a fictionalized style of staff dose 
% report into MATLAB.
% * How to write the staff dose data to an SQLite database
% * How to query the database
% * And how to process and plot the query results in boxplots 

% Requirements: this script requires that the Database Toolbox of MATLAB is 
% installed, along with the Statistics and Machine Learning Toolbox 
% (the latter only for creating the boxplots).

% We will clear the MATLAB workspace before beginning.

clear

%% 1. Define SQLite data fields and checks

fileFields = { {'Customer', 'VARCHAR'}, {'CustomerUID', 'INTEGER'}, ...
     {'Department', 'VARCHAR'}, {'DepartmentUID', 'INTEGER'}, ...
     {'Name', 'VARCHAR'}, {'PersonUID', 'INTEGER'}, ...
     {'RadiationType', 'VARCHAR'}, {'Hp10', 'DOUBLE'}, ...
     {'Hp007', 'DOUBLE'}, ...
     {'UserType', 'VARCHAR'}, {'DosimeterType', 'VARCHAR'}, ...
     {'DosimeterPlacement', 'VARCHAR'}, {'DosimeterUID', 'INTEGER'}, ...
     {'StartDate', 'DATE'}, {'EndDate', 'DATE'}, ...
     {'ReadDate', 'DATE'}, {'ReportDate', 'DATE'}, ...
     {'ReportUID', 'INTEGER'}};

addFields = {{'Status', 'VARCHAR'}};

check = ['CHECK( (Status IN (''NR'',''B'') AND ' ...
    '(Hp10 IS NULL AND Hp007 IS NULL)) OR ' ...
    '(Status IN (''OK'') AND '...
    '(Hp10 IS NOT NULL OR Hp007 IS NOT NULL))) '];

%% 2. Setup and configure SQLite database (if it doesn't exist)

databasePath = fullfile(pwd,'db-matlab');

if ~exist(databasePath, 'dir')
    mkdir(databasePath);
end

dbFile = fullfile(databasePath,'dose-matlab.db');

ourSource = 'SQLiteEMP';
dataSources = listDataSources();
createDataSource = (sum(dataSources.('Name') == ourSource) == 0);

if createDataSource
    vendor = 'Other';
    opts = databaseConnectionOptions('jdbc',vendor);
    opts = setoptions(opts, ...
    'DataSourceName',ourSource, ...
    'JDBCDriverLocation','lib-matlab/sqlite-jdbc-3.36.0.3.jar', ...
    'Driver','org.sqlite.JDBC', ...  
    'URL',strcat('jdbc:sqlite:',dbFile));
    saveAsDataSource(opts);
end

if ~isfile(dbFile)
    conn = database(ourSource,'',''); % Connect to the database
    createTable = getCreateTable('doseTable',fileFields,addFields,check); ...
        % Define and sql statement to create table
    execute(conn,createTable) % Create the sql table in the database
    close(conn); % Close the database connection
end

%% 3. Read data from Excel files and write to the database

newDataLocation = uigetdir(pwd,'Select a directory with dose reports');

files = dir(fullfile(newDataLocation,'*xls'));

conn = database(ourSource,'','');

nf = numel(files);
for i=1:nf % Iterate through the Excel files
    fpop = msgbox(['Processing file ' num2str(i) ' of ' num2str(nf)], ...
        'modal'); % Pop-up to indicate progress
    doseData = getDataFromExcel(files(i),fileFields); ...
        % See functions at end of script
    isNew = getIsNew(doseData,conn,'ReportUID',true); ...
        % See functions at end of script
    if ~isNew
        disp('Ignoring a file based on non-unique ReportNr')
        disp([files(i).name ' is already in the database']);
        continue
    end    
    nl = size(doseData,1);
    for j=1:nl % Iterate through rows of an Excel file (dosimeter readings)
        [rowData, colNames] = getRowData(fileFields,addFields, ...
            doseData(j,:)); % See functions at end of script
        insert(conn,'doseTable',colNames,rowData) ...
            % Insert data into the database
    end
end

if ishandle(fpop)
    close(fpop)
end

close(conn);

%% 4. Querying the database

conn = database('SQLiteEMP','','');

sqlQuery = ['SELECT PersonUID, Department, Hp10, EndDate FROM doseTable ' ...
    'WHERE DosimeterType = ''Badge'' AND Status IN (''OK'') ' ...
    'ORDER BY EndDate'];

results = fetch(conn,sqlQuery);

close(conn);

%% 5. Processing the results and plotting the data

EndDates = string(results.EndDate);
mask2020 = contains(EndDates,'2020');
mask2021 = contains(EndDates,'2021');

Departments = string(results.Department);
maskNM=contains(Departments,'Nuclear Medicine');
maskDR=contains(Departments,'Diagnostic Radiology');
maskRT=contains(Departments,'Radiotherapy');

figure

subplot(1,3,1) % Nuclear Medicine subplot

doses2020 = results(mask2020 & maskNM,:).('Hp10');
num2020 = numel(doses2020);
years2020 = strings(num2020,1);
years2020(1:num2020) = '2020';

doses2021 = results(mask2021 & maskNM,:).('Hp10');
num2021 = numel(doses2021);
years2021 = strings(num2021,1);
years2021(1:num2021) = '2021';

boxplot([doses2020;doses2021],[years2020;years2021],'symbol','r.', ...
    'OutlierSize',10)
ylim([0.04,0.205])
ylabel('Hp(10)')
xlabel('Nuclear Medicine')

subplot(1,3,2) % Diagnostic Radiology subplot

doses2020 = results(mask2020 & maskDR,:).('Hp10');
num2020 = numel(doses2020);
years2020 = strings(num2020,1);
years2020(1:num2020) = '2020';

doses2021 = results(mask2021 & maskDR,:).('Hp10');
num2021 = numel(doses2021);
years2021 = strings(num2021,1);
years2021(1:num2021) = '2021';

boxplot([doses2020;doses2021],[years2020;years2021],'symbol','r.', ...
    'OutlierSize',10)
ylim([0.04,0.205])
xlabel('Diagnostic Radiology')

subplot(1,3,3) % Radiotherapy subplot

doses2020 = results(mask2020 & maskRT,:).('Hp10');
num2020 = numel(doses2020);
years2020 = strings(num2020,1);
years2020(1:num2020) = '2020';

doses2021 = results(mask2021 & maskRT,:).('Hp10');
num2021 = numel(doses2021);
years2021 = strings(num2021,1);
years2021(1:num2021) = '2021';

boxplot([doses2020;doses2021],[years2020;years2021],'symbol','r.', ...
    'OutlierSize',10)
ylim([0.04,0.205])
xlabel('Radiotherapy')

%% 6. Bonus queries

conn = database('SQLiteEMP','','');
sqlQuery = ['SELECT StartDate, EndDate FROM doseTable ' ...
    'WHERE Status != ''NR'' ORDER BY StartDate ASC'];
results = fetch(conn,sqlQuery);
close(conn);

formatSpec = ...
    'Earliest and latest records of staff dose readings are %s and %s\n\n';
R1 = string(results{1,1});
R2 = string(results{end,1});
fprintf(formatSpec,R1,R2)

conn = database('SQLiteEMP','','');
sqlQuery = ['SELECT COUNT(Hp10) AS Nr_Hp10, COUNT(Hp007) AS Nr_Hp007, ' ...
    'DosimeterType FROM doseTable WHERE Status != ''NR'' ' ...
    'GROUP BY DosimeterType'];
results = fetch(conn,sqlQuery);
close(conn);

fprintf('Number of staff dose readings, per dosimeter type:\n\n'), ...
    disp(results)

conn = database('SQLiteEMP','','');
sqlQuery = ['SELECT Name, COUNT(Status == "NR") AS Instances ' ...
    'FROM doseTable WHERE Status == ''NR'' ' ...
    'GROUP BY NAME ORDER BY COUNT(Status = ''NR'') DESC'];
results = fetch(conn,sqlQuery);
close(conn);

fprintf('Individuals who did not return a dosimeter and number of instances:\n\n'), ...
    disp(results)

%% Appendix: functions used in the script
% Several custom functions are defined below that are used in the main body 
% of the script.

function t = getCreateTable(name,fileFields,addFields,check)
% getCreatTable returns a character array that can be passed to SQLite to
% define an SQL table in a database
%   t = getCreateTable(name,fileFields,addFields,check)
% where
%   name is the name of the SQL table
%   fieldFields is a cell array defining column names and SQLite types for
%     the data set
%   addFields is a cell array of any additional column names and SQLite
%     types
%   check is a character array defining an SQL data check statement
%   t is a character array returned by the function
%
   fieldDef = [fileFields addFields]; ...
       % Combine the two cell arrays together
   prefix = ['create table ' name ' (']; % Start of the SQL character array
   suffix = ')'; % End of the SQL character array
   n = numel(fieldDef);
   for i=1:n % Iterate through all the fields
       % Add the info (name and type) for the field to the prefix variable
       prefix = strcat(prefix,[char(fieldDef{i}{1}) ' ' ...
           char(fieldDef{i}{2}) ',']);
   end
   t = [prefix check suffix]; % Add the check statement and closing suffix
end


function d = getDataFromExcel(file,fileFields)
% getDataFromExcel reads data from an Excel file and overwrites the field
% names with user supplied values
%   d = getDataFromExcel(file,fileFields)
% where
%  file is a row of a MATLAB table corresponding to the details of a file,
%    as output by the dir() function
%  fileFields is a cell array with the names and SQLite types the user
%    wishes to use for the columns of the data (overwrites names in file)
%
    fullpath2file = fullfile(file.folder,file.name); % Path to Excel file
    opts = detectImportOptions(fullpath2file); % Get import options
    for i=1:numel(opts.VariableTypes)
        opts.VariableTypes{i} = 'string'; % Set import all data as strings
    end
    opts.VariableNamingRule = 'preserve'; % Set to preserve column names 
    d = readtable(fullpath2file,opts); % Read the data with the options
    c={}; % Create empty cell array    
    for i=1:numel(fileFields) % Iterate through fields i.e. Excel columns
        c{i}=fileFields{i}{1}; % Add field name to cell array
    end   
    d.Properties.VariableNames = c; % Overwite all field names
end


function i = getIsNew(doseData,conn,uidName,safe)
% getIsNew tests whether data is already saved in a database
%   i = getIsNew(doseData,conn,uidName,safe)
% where
%   doseData is a MATLAB table of data
%   conn is a connection to an SQLite database
%   uidName is a table field that contains a value unique to the data
%   safe is a logical parameter; if true, safer code is employed that
%     prevents SQL injection
%   i is the returned value (1 for new and 0 for already saved)
%
    uid = doseData.(uidName){1}; % Only checks the first data row
    if ~safe % Allows SQL Injection
        sqlQuery = ['SELECT ' uidName ' FROM doseTable WHERE ' ...
        uidName '==' uid] % Define the SQL query
        results = fetch(conn,sqlQuery) % Get the results
    else % Prevents SQL Injection
        selection = [1 2]; % First and second question marks (parameters)
        values = {uidName, uid}; % Values corresponding to the parameters
        sqlQuery = ['SELECT ? FROM doseTable WHERE  ' uidName ' == ?']; ... 
            % Parameterize the SQL query
        pstmt = ...
            databasePreparedStatement(conn,sqlQuery); % Prepare statement
        pstmt = bindParamValues(pstmt,selection,values); % Bind values
        results = fetch(conn,pstmt); % Get the results
        close(pstmt)
    end
    if numel(results) ~= 0 
        i = 0; % If results is not empty, assign 0 (not new)
    else
        i = 1; % If results is empty, assign 1 (new)
    end 
end


function [r, c] = getRowData(fileFields,addFields,doseData)
% getRowData returns data for a row of the SQL table in a format that
% can be written to an SQLite database. The column names are also returned.
%   [r, c] = getRowData(fileFields,addFields,doseData)
% where
%   fieldFields is a cell array with the field names and types
%     corresponding to the data from an Excel file
%   addFields is a cell array with any additional field names and types
%   doseData is a MATLAB table with the data from an Excel file
%   r is a cell array with row data for writing to an SQLite database
%   c is a cell array with the column names corresponding to the rows
%
    nel = numel(doseData);
    r = {}; % Empty cell array to contain row data
    for k=1:nel % Iterate through columns of the doseData MATLAB table
        fieldname= fileFields{k}{1}; % Field name for the field
        typename = fileFields{k}{2}; % SQLite type for the field
        dataitem = doseData.(fieldname)(1); % Data value (as MATLAB string)
        if strcmp(typename,'VARCHAR') % If SQLite type is VARCHAR
            if dataitem=="NR" % If data value is "Not Returned"
                data = string(missing()); % Define element as missing
            else % Otherwise
                data=string(dataitem); % Define element as string
            end
        elseif strcmp(typename,'DATE') % If SQLite type is DATE
            if dataitem=="NR" % If data value is "Not Returned"
                data = NaT; % Define element as "Not a Datetime" (NaT)
            else % Otherwise
                data=datetime(dataitem,'InputFormat','dd-MMM-yyyy'); ...
                    % To datetime
            end
        elseif strcmp(typename,'DOUBLE') | strcmp(typename,'INTEGER') ...
                % If SQLite type DOUBLE/INTEGER
            if dataitem == "B" | ismissing(dataitem) | dataitem=="NR" ...
                    % If "Below Threshold", missing or "Not returned"
                data = NaN; % Set to Not a Number (NaN)
            else % Otherwise
                data = str2num(replace(dataitem,',','.')); ... 
                    % Convert to MATLAB double
            end
        end
        r{k} = data; % Append the data element to the row cell array
    end
    % Append a final element to the cell array corresponding to the field 
    % in addFields. This field is "Status" and indicates whether the 
    % reading to below threshold (B), not returned (NR) or valid (OK)
    if doseData.('Hp10')(1) == "B" | doseData.('Hp007')(1) == "B"
        r{nel+1} = "B";
    elseif doseData.('ReadDate')(1) == "NR" 
        r{nel+1} = "NR";
    else
        r{nel+1} = "OK";
    end
    fieldDef = [fileFields addFields]; % Cell array of all fields
    c={}; % Empty cell array to contain column names (fields)
    for i=1:numel(fieldDef) % Iterate through fields
        c{i}=fieldDef{i}{1}; % Append field name to column cell array
    end
end