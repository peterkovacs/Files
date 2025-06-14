/**
 *  Files
 *
 *  Copyright (c) 2017-2019 John Sundell. Licensed under the MIT license, as follows:
 *
 *  Permission is hereby granted, free of charge, to any person obtaining a copy
 *  of this software and associated documentation files (the "Software"), to deal
 *  in the Software without restriction, including without limitation the rights
 *  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 *  copies of the Software, and to permit persons to whom the Software is
 *  furnished to do so, subject to the following conditions:
 *
 *  The above copyright notice and this permission notice shall be included in all
 *  copies or substantial portions of the Software.
 *
 *  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 *  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 *  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 *  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 *  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 *  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 *  SOFTWARE.
 */

import Foundation
import Testing
import Files

@Suite(.serialized) class FilesTests {
    private var folder: Folder

    init() throws {
        folder = try Folder.home.createSubfolderIfNeeded(withName: ".filesTest")
        try folder.empty()
    }

    deinit {
        try? folder.delete()
    }

    // MARK: - Tests
    
    @Test func testCreatingAndDeletingFile() throws {
        try performTest {
            // Verify that the file doesn't exist
            #expect(!folder.containsFile(named: "test.txt"))

            // Create a file and verify its properties
            let file = try folder.createFile(named: "test.txt")
            #expect(file.name ==  "test.txt")
            #expect(file.path ==  folder.path + "test.txt")
            #expect(file.extension ==  "txt")
            #expect(file.nameExcludingExtension ==  "test")
            try #expect(file.read() ==  Data())
            
            // You should now be able to access the file using its path and through the parent
            _ = try File(path: file.path)
            #expect(folder.containsFile(named: "test.txt"))

            try file.delete()

            // Attempting to read the file should now throw an error
            #expect(throws: ReadError.self) {
                try file.read()
            }

            // Attempting to create a File instance with the path should now also fail
            #expect(throws: LocationError.self) {
                try File(path: file.path)
            }
        }
    }

    @Test func testCreatingFileAtPath() throws {
        try performTest {
            let path = "a/b/c.txt"

            #expect(!folder.containsFile(at: path))
            try folder.createFile(at: path, contents: Data("Hello".utf8))

            #expect(folder.containsFile(at: path))
            #expect(folder.containsSubfolder(named: "a"))
            #expect(folder.containsSubfolder(at: "a/b"))

            let file = try folder.createFileIfNeeded(at: path)
            #expect(try file.readAsString() ==  "Hello")
        }
    }

    @Test func testCreatingFileIfNeededAtPath() throws {
        try performTest {
            let path = "a/b/c.txt"

            #expect(!folder.containsFile(at: path))
            var file = try folder.createFileIfNeeded(at: path, contents: Data("Hello".utf8))

            #expect(folder.containsFile(at: path))
            #expect(folder.containsSubfolder(named: "a"))
            #expect(folder.containsSubfolder(at: "a/b"))

            file = try folder.createFileIfNeeded(at: path, contents: Data())
            #expect(try file.readAsString() ==  "Hello")
        }
    }

    @Test func testDroppingLeadingSlashWhenCreatingFileAtPath() throws {
        try performTest {
            let path = "/a/b/c.txt"

            #expect(!folder.containsFile(at: path))
            try folder.createFile(at: path, contents: Data("Hello".utf8))

            #expect(folder.containsFile(at: path))
            #expect(folder.containsSubfolder(named: "a"))
            #expect(folder.containsSubfolder(at: "/a/b"))

            let file = try folder.createFileIfNeeded(at: path)
            #expect(try file.readAsString() ==  "Hello")
        }
    }
    
    @Test func testCreatingAndDeletingFolder() throws {
        try performTest {
            // Verify that the folder doesn't exist
            #expect(!folder.containsSubfolder(named: "folder"))

            // Create a folder and verify its properties
            let subfolder = try folder.createSubfolder(named: "folder")
            #expect(subfolder.name ==  "folder")
            #expect(subfolder.path ==  folder.path + "folder/")
            
            // You should now be able to access the folder using its path and through the parent
            _ = try Folder(path: subfolder.path)
            #expect(folder.containsSubfolder(named: "folder"))
            
            // Put a file in the folder
            let file = try subfolder.createFile(named: "file")
            try #expect(file.read() ==  Data())
            
            try subfolder.delete()

            // Attempting to create a Folder instance with the path should now fail
            #expect(throws: LocationError.self) {
                try Folder(path: subfolder.path)
            }

            // The file contained in the folder should now also be deleted
            #expect(throws: ReadError.self) {
                try file.read()
            }
        }
    }

    @Test func testCreatingSubfolderAtPath() throws {
        try performTest {
            let path = "a/b/c"

            #expect(!folder.containsSubfolder(at: path))
            try folder.createSubfolder(at: path).createFile(named: "d.txt")

            #expect(folder.containsSubfolder(at: path))
            #expect(folder.containsSubfolder(named: "a"))
            #expect(folder.containsSubfolder(at: "a/b"))
            #expect(folder.containsFile(at: "a/b/c/d.txt"))

            let subfolder = try folder.createSubfolderIfNeeded(at: path)
            #expect(subfolder.files.names() ==  ["d.txt"])
        }
    }

    @Test func testDroppingLeadingSlashWhenCreatingSubfolderAtPath() throws {
        try performTest {
            let path = "a/b/c"

            #expect(!folder.containsSubfolder(at: path))
            try folder.createSubfolder(at: path).createFile(named: "d.txt")

            #expect(folder.containsSubfolder(at: path))
            #expect(folder.containsSubfolder(named: "a"))
            #expect(folder.containsSubfolder(at: "/a/b"))
            #expect(folder.containsFile(at: "/a/b/c/d.txt"))

            let subfolder = try folder.createSubfolderIfNeeded(at: path)
            #expect(subfolder.files.names() ==  ["d.txt"])
        }
    }

    @Test func testReadingFileAsString() throws {
        try performTest {
            let file = try folder.createFile(named: "string", contents: "Hello".data(using: .utf8)!)
            try #expect(file.readAsString() ==  "Hello")
        }
    }

    @Test func testReadingFileAsInt() throws {
        try performTest {
            let intFile = try folder.createFile(named: "int", contents: "\(7)".data(using: .utf8)!)
            try #expect(intFile.readAsInt() ==  7)

            let nonIntFile = try folder.createFile(named: "nonInt", contents: "Not an int".data(using: .utf8)!)
            #expect(throws: ReadError.self) {
                try nonIntFile.readAsInt()
            }
        }
    }
    
    @Test func testRenamingFile() throws {
        try performTest {
            let file = try folder.createFile(named: "file.json")
            try file.rename(to: "renamedFile")
            #expect(file.name ==  "renamedFile.json")
            #expect(file.path ==  folder.path + "renamedFile.json")
            #expect(file.extension ==  "json")
            
            // Now try renaming the file, replacing its extension
            try file.rename(to: "other.txt", keepExtension: false)
            #expect(file.name ==  "other.txt")
            #expect(file.path ==  folder.path + "other.txt")
            #expect(file.extension ==  "txt")
        }
    }
    
    @Test func testRenamingFileWithNameIncludingExtension() throws {
        try performTest {
            let file = try folder.createFile(named: "file.json")
            try file.rename(to: "renamedFile.json")
            #expect(file.name ==  "renamedFile.json")
            #expect(file.path ==  folder.path + "renamedFile.json")
            #expect(file.extension ==  "json")
        }
    }
    
    @Test func testReadingFileWithRelativePath() throws {
        try performTest {
            try folder.createFile(named: "file")
            
            // Make sure we're not already in the file's parent directory
            #expect(FileManager.default.currentDirectoryPath != folder.path)
            
            #expect(FileManager.default.changeCurrentDirectoryPath(folder.path))
            let file = try File(path: "file")
            try #expect(file.read() ==  Data())
        }
    }
    
    @Test func testReadingFileWithTildePath() throws {
        try performTest {
            try folder.createFile(named: "File")
            let file = try File(path: "~/.filesTest/File")
            try #expect(file.read() ==  Data())
            #expect(file.path ==  folder.path + "File")

            // Cleanup since we're performing a test in the actual home folder
            try file.delete()
        }
    }

    @Test func testReadingFileFromCurrentFoldersParent() throws {
        try performTest {
            let subfolder = try folder.createSubfolder(named: "folder")
            let file = try folder.createFile(named: "file")

            // Move to the subfolder
            #expect(FileManager.default.currentDirectoryPath != subfolder.path)
            #expect(FileManager.default.changeCurrentDirectoryPath(subfolder.path))

            try #expect(File(path: "../file") ==  file)
        }
    }

    @Test func testReadingFileWithMultipleParentReferencesWithinPath() throws {
        try performTest {
            let subfolderA = try folder.createSubfolder(named: "A")
            try folder.createSubfolder(named: "B")
            let subfolderC = try folder.createSubfolder(named: "C")
            let file = try subfolderC.createFile(named: "file")

            try #expect(File(path: subfolderA.path + "../B/../C/file") ==  file)
        }
    }
    
    @Test func testRenamingFolder() throws {
        try performTest {
            let subfolder = try folder.createSubfolder(named: "folder")
            try subfolder.rename(to: "renamedFolder")
            #expect(subfolder.name ==  "renamedFolder")
            #expect(subfolder.path ==  folder.path + "renamedFolder/")
        }
    }

    @Test func testAccesingFileByPath() throws {
        try performTest {
            let subfolderA = try folder.createSubfolder(named: "A")
            let subfolderB = try subfolderA.createSubfolder(named: "B")
            let file = try subfolderB.createFile(named: "C")
            try #expect(folder.file(at: "A/B/C") ==  file)
        }
    }

    @Test func testAccessingSubfolderByPath() throws {
        try performTest {
            let subfolderA = try folder.createSubfolder(named: "A")
            let subfolderB = try subfolderA.createSubfolder(named: "B")
            let subfolderC = try subfolderB.createSubfolder(named: "C")
            try #expect(folder.subfolder(at: "A/B/C") ==  subfolderC)
        }
    }

    @Test func testEmptyingFolder() throws {
        try performTest {
            try folder.createFile(named: "A")
            try folder.createFile(named: "B")
            #expect(folder.files.count() ==  2)

            try folder.empty()
            #expect(folder.files.count() ==  0)
        }
    }

    @Test func testEmptyingFolderWithHiddenFiles() throws {
        try performTest {
            let subfolder = try folder.createSubfolder(named: "folder")

            try subfolder.createFile(named: "A")
            try subfolder.createFile(named: ".B")
            #expect(subfolder.files.includingHidden.count() ==  2)

            // Per default, hidden files should not be deleted
            try subfolder.empty()
            #expect(subfolder.files.includingHidden.count() ==  1)

            try subfolder.empty(includingHidden: true)
            #expect(folder.files.count() ==  0)
        }
    }
    
    @Test func testCheckingEmptyFolders() throws {
        try performTest {
            let emptySubfolder = try folder.createSubfolder(named: "1")
            #expect(emptySubfolder.isEmpty())
            
            let subfolderWithFile = try folder.createSubfolder(named: "2")
            try subfolderWithFile.createFile(named: "A")
            #expect(!subfolderWithFile.isEmpty())
            
            let subfolderWithHiddenFile = try folder.createSubfolder(named: "3")
            try subfolderWithHiddenFile.createFile(named: ".B")
            #expect(subfolderWithHiddenFile.isEmpty())
            #expect(!subfolderWithHiddenFile.isEmpty(includingHidden: true))
            
            let subfolderWithFolder = try folder.createSubfolder(named: "3")
            try subfolderWithFolder.createSubfolder(named: "4")
            #expect(!subfolderWithFile.isEmpty())
        }
    }

    @Test func testMovingFiles() throws {
        try performTest {
            try folder.createFile(named: "A")
            try folder.createFile(named: "B")
            #expect(folder.files.count() ==  2)
            
            let subfolder = try folder.createSubfolder(named: "folder")
            try folder.files.move(to: subfolder)
            _ = try subfolder.file(named: "A")
            _ = try subfolder.file(named: "B")
            #expect(folder.files.count() ==  0)
        }
    }
    
    @Test func testCopyingFiles() throws {
        try performTest {
            let file = try folder.createFile(named: "A")
            try file.write("content")
            
            let subfolder = try folder.createSubfolder(named: "folder")
            let copiedFile = try file.copy(to: subfolder)
            _ = try folder.file(named: "A")
            let subA = try subfolder.file(named: "A")
            #expect(try file.read() == subA.read())
            #expect(try copiedFile == subfolder.file(named: "A"))
            #expect(folder.files.count() ==  1)
        }
    }

    @Test func testMovingFolders() throws {
        try performTest {
            let a = try folder.createSubfolder(named: "A")
            let b = try a.createSubfolder(named: "B")
            _ = try b.createSubfolder(named: "C")

            try b.move(to: folder)
            #expect(folder.containsSubfolder(named: "B"))
            #expect(b.containsSubfolder(named: "C"))
        }
    }
    
    @Test func testCopyingFolders() throws {
        try performTest {
            let copyingFolder = try folder.createSubfolder(named: "A")
            
            let subfolder = try folder.createSubfolder(named: "folder")
            let copiedFolder = try copyingFolder.copy(to: subfolder)
            #expect(folder.containsSubfolder(named: "A"))
            #expect(subfolder.containsSubfolder(named: "A"))
            #expect(try subfolder.subfolder(named: "A") == copiedFolder)
            #expect(folder.subfolders.count() ==  2)
            #expect(subfolder.subfolders.count() ==  1)
        }
    }
    
    @Test func testEnumeratingFiles() throws {
        try performTest {
            try folder.createFile(named: "1")
            try folder.createFile(named: "2")
            try folder.createFile(named: "3")
            
            // Hidden files should be excluded by default
            try folder.createFile(named: ".hidden")
            
            #expect(folder.files.names().sorted() ==  ["1", "2", "3"])
            #expect(folder.files.count() ==  3)
        }
    }
    
    @Test func testEnumeratingFilesIncludingHidden() throws {
        try performTest {
            let subfolder = try folder.createSubfolder(named: "folder")
            try subfolder.createFile(named: ".hidden")
            try subfolder.createFile(named: "visible")
            
            let files = subfolder.files.includingHidden
            #expect(files.names().sorted() ==  [".hidden", "visible"])
            #expect(files.count() ==  2)
        }
    }
    
    @Test func testEnumeratingFilesRecursively() throws {
        try performTest {
            let subfolder1 = try folder.createSubfolder(named: "1")
            let subfolder2 = try folder.createSubfolder(named: "2")
            
            let subfolder1A = try subfolder1.createSubfolder(named: "A")
            let subfolder1B = try subfolder1.createSubfolder(named: "B")
            
            let subfolder2A = try subfolder2.createSubfolder(named: "A")
            let subfolder2B = try subfolder2.createSubfolder(named: "B")
            
            try subfolder1.createFile(named: "File1")
            try subfolder1A.createFile(named: "File1A")
            try subfolder1B.createFile(named: "File1B")
            try subfolder2.createFile(named: "File2")
            try subfolder2A.createFile(named: "File2A")
            try subfolder2B.createFile(named: "File2B")
            
            let expectedNames = ["File1", "File1A", "File1B", "File2", "File2A", "File2B"]
            let sequence = folder.files.recursive
            #expect(sequence.names() ==  expectedNames)
            #expect(sequence.count() ==  6)
        }
    }
    
    @Test func testEnumeratingSubfolders() throws {
        try performTest {
            try folder.createSubfolder(named: "1")
            try folder.createSubfolder(named: "2")
            try folder.createSubfolder(named: "3")
            
            #expect(folder.subfolders.names() ==  ["1", "2", "3"])
            #expect(folder.subfolders.count() ==  3)
        }
    }
    
    @Test func testEnumeratingSubfoldersRecursively() throws {
        try performTest {
            let subfolder1 = try folder.createSubfolder(named: "1")
            let subfolder2 = try folder.createSubfolder(named: "2")
            
            try subfolder1.createSubfolder(named: "1A")
            try subfolder1.createSubfolder(named: "1B")
            
            try subfolder2.createSubfolder(named: "2A")
            try subfolder2.createSubfolder(named: "2B")
            
            let expectedNames = ["1", "1A", "1B", "2", "2A", "2B"]
            let sequence = folder.subfolders.recursive
            #expect(sequence.names().sorted() ==  expectedNames)
            #expect(sequence.count() ==  6)
        }
    }

    @Test func testRenamingFoldersWhileEnumeratingSubfoldersRecursively() throws {
        try performTest {
            let subfolder1 = try folder.createSubfolder(named: "1")
            let subfolder2 = try folder.createSubfolder(named: "2")

            try subfolder1.createSubfolder(named: "1A")
            try subfolder1.createSubfolder(named: "1B")

            try subfolder2.createSubfolder(named: "2A")
            try subfolder2.createSubfolder(named: "2B")

            let sequence = folder.subfolders.recursive

            for folder in sequence {
                try folder.rename(to: "Folder " + folder.name)
            }

            let expectedNames = ["Folder 1", "Folder 1A", "Folder 1B", "Folder 2", "Folder 2A", "Folder 2B"]

            #expect(sequence.names().sorted() ==  expectedNames)
            #expect(sequence.count() ==  6)
        }
    }
    
    @Test func testFirstAndLastInFileSequence() throws {
        try performTest {
            try folder.createFile(named: "A")
            try folder.createFile(named: "B")
            try folder.createFile(named: "C")
            
            #expect(folder.files.first?.name ==  "A")
            #expect(folder.files.last()?.name ==  "C")
        }
    }

    @Test func testConvertingFileSequenceToRecursive() throws {
        try performTest {
            try folder.createFile(named: "A")
            try folder.createFile(named: "B")

            let subfolder = try folder.createSubfolder(named: "1")
            try subfolder.createFile(named: "1A")

            let names = folder.files.recursive.names()
            #expect(names ==  ["A", "B", "1A"])
        }
    }

    @Test func testModificationDate() throws {
        try performTest {
            let subfolder = try folder.createSubfolder(named: "Folder")
            #expect(subfolder.modificationDate.map(Calendar.current.isDateInToday) ?? false)

            let file = try folder.createFile(named: "File")
            #expect(file.modificationDate.map(Calendar.current.isDateInToday) ?? false)
        }
    }
    
    @Test func testParent() throws {
        try performTest {
            try #expect(folder.createFile(named: "test").parent ==  folder)
            
            let subfolder = try folder.createSubfolder(named: "subfolder")
            #expect(subfolder.parent ==  folder)
            try #expect(subfolder.createFile(named: "test").parent ==  subfolder)
        }
    }
    
    @Test func testRootFolderParentIsNil() throws {
        try performTest {
            try #expect(Folder(path: "/").parent == nil)
        }
    }
    
    @Test func testRootSubfolderParentIsRoot() throws {
        try performTest {
            let rootFolder = try Folder(path: "/")
            let subfolder = rootFolder.subfolders.first
            #expect(subfolder?.parent ==  rootFolder)
        }
    }
    
    @Test func testOpeningFileWithEmptyPathThrows() throws {
        try performTest {
            #expect(throws: LocationError.self) {
                try File(path: "")
            }
        }
    }
    
    @Test func testDeletingNonExistingFileThrows() throws {
        try performTest {
            let file = try folder.createFile(named: "file")
            try file.delete()
            #expect(throws: LocationError.self) {
                try file.delete()
            }
        }
    }
    
    @Test func testWritingDataToFile() throws {
        try performTest {
            let file = try folder.createFile(named: "file")
            try #expect(file.read() ==  Data())
            
            let data = "New content".data(using: .utf8)!
            try file.write(data)
            try #expect(file.read() ==  data)
        }
    }
    
    @Test func testWritingStringToFile() throws {
        try performTest {
            let file = try folder.createFile(named: "file")
            try #expect(file.read() ==  Data())
            
            try file.write("New content")
            try #expect(file.read() ==  "New content".data(using: .utf8))
        }
    }

    @Test func testAppendingDataToFile() throws {
        try performTest {
            let file = try folder.createFile(named: "file")
            let data = "Old content\n".data(using: .utf8)!
            try file.write(data)

            let newData = "I'm the appended content 💯\n".data(using: .utf8)!
            try file.append(newData)
            try #expect(file.read() ==  "Old content\nI'm the appended content 💯\n".data(using: .utf8))
        }
    }

    @Test func testAppendingStringToFile() throws {
        try performTest {
            let file = try folder.createFile(named: "file")
            try file.write("Old content\n")

            let newString = "I'm the appended content 💯\n"
            try file.append(newString)
            try #expect(file.read() ==  "Old content\nI'm the appended content 💯\n".data(using: .utf8))
        }
    }
    
    @Test func testFileDescription() throws {
        try performTest {
            let file = try folder.createFile(named: "file")
            #expect(file.description ==  "File(name: file, path: \(folder.path)file)")
        }
    }
    
    @Test func testFolderDescription() throws {
        try performTest {
            let subfolder = try folder.createSubfolder(named: "folder")
            #expect(subfolder.description ==  "Folder(name: folder, path: \(folder.path)folder/)")
        }
    }

    @Test func testFilesDescription() throws {
        try performTest {
            let fileA = try folder.createFile(named: "fileA")
            let fileB = try folder.createFile(named: "fileB")
            #expect(folder.files.description ==  "\(fileA.description)\n\(fileB.description)")
        }
    }

    @Test func testSubfoldersDescription() throws {
        try performTest {
            let folderA = try folder.createSubfolder(named: "folderA")
            let folderB = try folder.createSubfolder(named: "folderB")
            #expect(folder.subfolders.description ==  "\(folderA.description)\n\(folderB.description)")
        }
    }

    @Test func testMovingFolderContents() throws {
        try performTest {
            let parentFolder = try folder.createSubfolder(named: "parentA")
            try parentFolder.createSubfolder(named: "folderA")
            try parentFolder.createSubfolder(named: "folderB")
            try parentFolder.createFile(named: "fileA")
            try parentFolder.createFile(named: "fileB")

            #expect(parentFolder.subfolders.names() ==  ["folderA", "folderB"])
            #expect(parentFolder.files.names() ==  ["fileA", "fileB"])

            let newParentFolder = try folder.createSubfolder(named: "parentB")
            try parentFolder.moveContents(to: newParentFolder)

            #expect(parentFolder.subfolders.names() ==  [])
            #expect(parentFolder.files.names() ==  [])
            #expect(newParentFolder.subfolders.names() ==  ["folderA", "folderB"])
            #expect(newParentFolder.files.names() ==  ["fileA", "fileB"])
        }
    }
    
    @Test func testMovingFolderHiddenContents() throws {
        try performTest {
            let parentFolder = try folder.createSubfolder(named: "parent")
            try parentFolder.createFile(named: ".hidden")
            try parentFolder.createSubfolder(named: ".folder")
            
            #expect(parentFolder.files.includingHidden.names() ==  [".hidden"])
            #expect(parentFolder.subfolders.includingHidden.names() ==  [".folder"])
            
            let newParentFolder = try folder.createSubfolder(named: "parentB")
            try parentFolder.moveContents(to: newParentFolder, includeHidden: true)
            
            #expect(parentFolder.files.includingHidden.names() ==  [])
            #expect(parentFolder.subfolders.includingHidden.names() ==  [])
            #expect(newParentFolder.files.includingHidden.names() ==  [".hidden"])
            #expect(newParentFolder.subfolders.includingHidden.names() ==  [".folder"])
        }
    }

    @Test func testAccessingHomeFolder() throws {
        Folder.home
    }

    @Test func testAccessingCurrentWorkingDirectory() throws {
        try performTest {
            let folder = try Folder(path: "")
            #expect(FileManager.default.currentDirectoryPath + "/" ==  folder.path)
            #expect(Folder.current ==  folder)
        }
    }
    
    @Test func testNameExcludingExtensionWithLongFileName() throws {
        try performTest {
            let file = try folder.createFile(named: "AVeryLongFileName.png")
            #expect(file.nameExcludingExtension ==  "AVeryLongFileName")
        }
    }

    @Test func testNameExcludingExtensionWithoutExtension() throws {
        try performTest {
            let file = try folder.createFile(named: "File")
            let subfolder = try folder.createSubfolder(named: "Subfolder")

            #expect(file.nameExcludingExtension ==  "File")
            #expect(subfolder.nameExcludingExtension ==  "Subfolder")
        }
    }

    @Test func testRelativePaths() throws {
        try performTest {
            let file = try folder.createFile(named: "FileA")
            let subfolder = try folder.createSubfolder(named: "Folder")
            let fileInSubfolder = try subfolder.createFile(named: "FileB")

            #expect(file.path(relativeTo: folder) ==  "FileA")
            #expect(subfolder.path(relativeTo: folder) ==  "Folder")
            #expect(fileInSubfolder.path(relativeTo: folder) ==  "Folder/FileB")
        }
    }

    @Test func testRelativePathIsAbsolutePathForNonParent() throws {
        try performTest {
            let file = try folder.createFile(named: "FileA")
            let subfolder = try folder.createSubfolder(named: "Folder")

            #expect(file.path(relativeTo: subfolder) ==  file.path)
        }
    }

    @Test func testCreateFileIfNeeded() throws {
        try performTest {
            let fileA = try folder.createFileIfNeeded(withName: "file", contents: "Hello".data(using: .utf8)!)
            let fileB = try folder.createFileIfNeeded(withName: "file", contents: "World".data(using: .utf8)!)
            #expect(try fileA.readAsString() ==  "Hello")
            #expect(try fileA.read() ==  fileB.read())
        }
    }

    @Test func testCreateFolderIfNeeded() throws {
        try performTest {
            let subfolderA = try folder.createSubfolderIfNeeded(withName: "Subfolder")
            try subfolderA.createFile(named: "file")
            let subfolderB = try folder.createSubfolderIfNeeded(withName: subfolderA.name)
            #expect(subfolderA ==  subfolderB)
            #expect(subfolderA.files.count() ==  subfolderB.files.count())
            #expect(subfolderA.files.first ==  subfolderB.files.first)
        }
    }

    @Test func testCreateSubfolderIfNeeded() throws {
        try performTest {
            let subfolderA = try folder.createSubfolderIfNeeded(withName: "folder")
            try subfolderA.createFile(named: "file")
            let subfolderB = try folder.createSubfolderIfNeeded(withName: "folder")
            #expect(subfolderA ==  subfolderB)
            #expect(subfolderA.files.count() ==  subfolderB.files.count())
            #expect(subfolderA.files.first ==  subfolderB.files.first)
        }
    }
    
    @Test func testCreatingFileWithString() throws {
        try performTest {
            let file = try folder.createFile(named: "file", contents: Data("Hello world".utf8))
            #expect(try file.readAsString() ==  "Hello world")
        }
    }
    
    @Test func testUsingCustomFileManager() throws {
        class FileManagerMock: FileManager {
            var noFilesExist = false
            
            override func fileExists(atPath path: String, isDirectory: UnsafeMutablePointer<ObjCBool>?) -> Bool {
                if noFilesExist {
                    return false
                }
                
                return super.fileExists(atPath: path, isDirectory: isDirectory)
            }
        }
        
        try performTest {
            let fileManager = FileManagerMock()
            let subfolder = try folder.managedBy(fileManager).createSubfolder(named: UUID().uuidString)
            let file = try subfolder.createFile(named: "file")
            try #expect(file.read() ==  Data())
        
            // Mock that no files exist, which should call file lookups to fail
            fileManager.noFilesExist = true
            #expect(throws: LocationError.self) {
                try subfolder.file(named: "file")
            }
        }
    }

    @Test func testFolderContainsFile() throws {
        try performTest {
            let subfolder = try folder.createSubfolder(named: "subfolder")
            let fileA = try subfolder.createFile(named: "A")
            #expect(!folder.contains(fileA))

            let fileB = try folder.createFile(named: "B")
            #expect(folder.contains(fileB))
        }
    }

    @Test func testFolderContainsSubfolder() throws {
        try performTest {
            let subfolder = try folder.createSubfolder(named: "subfolder")
            let subfolderA = try subfolder.createSubfolder(named: "A")
            #expect(!folder.contains(subfolderA))

            let subfolderB = try folder.createSubfolder(named: "B")
            #expect(folder.contains(subfolderB))
        }
    }

    @Test func testErrorDescriptions() throws {
        let missingError = FilesError(
            path: "/some/path",
            reason: LocationErrorReason.missing
        )

        #expect(missingError.description ==  """
        Files encountered an error at '/some/path'.
        Reason: missing
        """)

        let encodingError = FilesError(
            path: "/some/path",
            reason: WriteErrorReason.stringEncodingFailed("Hello")
        )

        #expect(encodingError.description ==  """
        Files encountered an error at '/some/path'.
        Reason: stringEncodingFailed(\"Hello\")
        """)
    }
    
    // MARK: - Utilities
    
    private func performTest(closure: () throws -> Void) throws {
        try folder.empty()
        try closure()
    }

    // MARK: - Linux
    
    static let allTests = [
        ("testCreatingAndDeletingFile", testCreatingAndDeletingFile),
        ("testCreatingFileAtPath", testCreatingFileAtPath),
        ("testDroppingLeadingSlashWhenCreatingFileAtPath", testDroppingLeadingSlashWhenCreatingFileAtPath),
        ("testCreatingAndDeletingFolder", testCreatingAndDeletingFolder),
        ("testCreatingSubfolderAtPath", testCreatingSubfolderAtPath),
        ("testDroppingLeadingSlashWhenCreatingSubfolderAtPath", testDroppingLeadingSlashWhenCreatingSubfolderAtPath),
        ("testReadingFileAsString", testReadingFileAsString),
        ("testReadingFileAsInt", testReadingFileAsInt),
        ("testRenamingFile", testRenamingFile),
        ("testRenamingFileWithNameIncludingExtension", testRenamingFileWithNameIncludingExtension),
        ("testReadingFileWithRelativePath", testReadingFileWithRelativePath),
        ("testReadingFileWithTildePath", testReadingFileWithTildePath),
        ("testReadingFileFromCurrentFoldersParent", testReadingFileFromCurrentFoldersParent),
        ("testReadingFileWithMultipleParentReferencesWithinPath", testReadingFileWithMultipleParentReferencesWithinPath),
        ("testRenamingFolder", testRenamingFolder),
        ("testAccesingFileByPath", testAccesingFileByPath),
        ("testAccessingSubfolderByPath", testAccessingSubfolderByPath),
        ("testEmptyingFolder", testEmptyingFolder),
        ("testEmptyingFolderWithHiddenFiles", testEmptyingFolderWithHiddenFiles),
        ("testCheckingEmptyFolders", testCheckingEmptyFolders),
        ("testMovingFiles", testMovingFiles),
        ("testCopyingFiles", testCopyingFiles),
        ("testCopyingFolders", testCopyingFolders),
        ("testEnumeratingFiles", testEnumeratingFiles),
        ("testEnumeratingFilesIncludingHidden", testEnumeratingFilesIncludingHidden),
        ("testEnumeratingFilesRecursively", testEnumeratingFilesRecursively),
        ("testEnumeratingSubfolders", testEnumeratingSubfolders),
        ("testEnumeratingSubfoldersRecursively", testEnumeratingSubfoldersRecursively),
        ("testRenamingFoldersWhileEnumeratingSubfoldersRecursively", testRenamingFoldersWhileEnumeratingSubfoldersRecursively),
        ("testFirstAndLastInFileSequence", testFirstAndLastInFileSequence),
        ("testConvertingFileSequenceToRecursive", testConvertingFileSequenceToRecursive),
        ("testModificationDate", testModificationDate),
        ("testParent", testParent),
        ("testRootFolderParentIsNil", testRootFolderParentIsNil),
        ("testRootSubfolderParentIsRoot", testRootSubfolderParentIsRoot),
        ("testOpeningFileWithEmptyPathThrows", testOpeningFileWithEmptyPathThrows),
        ("testDeletingNonExistingFileThrows", testDeletingNonExistingFileThrows),
        ("testWritingDataToFile", testWritingDataToFile),
        ("testWritingStringToFile", testWritingStringToFile),
        ("testAppendingDataToFile", testAppendingDataToFile),
        ("testAppendingStringToFile", testAppendingStringToFile),
        ("testFileDescription", testFileDescription),
        ("testFolderDescription", testFolderDescription),
        ("testFilesDescription", testFilesDescription),
        ("testSubfoldersDescription", testSubfoldersDescription),
        ("testMovingFolderContents", testMovingFolderContents),
        ("testMovingFolderHiddenContents", testMovingFolderHiddenContents),
        ("testAccessingHomeFolder", testAccessingHomeFolder),
        ("testAccessingCurrentWorkingDirectory", testAccessingCurrentWorkingDirectory),
        ("testNameExcludingExtensionWithLongFileName", testNameExcludingExtensionWithLongFileName),
        ("testRelativePaths", testRelativePaths),
        ("testRelativePathIsAbsolutePathForNonParent", testRelativePathIsAbsolutePathForNonParent),
        ("testCreateFileIfNeeded", testCreateFileIfNeeded),
        ("testCreateFolderIfNeeded", testCreateFolderIfNeeded),
        ("testCreateSubfolderIfNeeded", testCreateSubfolderIfNeeded),
        ("testCreatingFileWithString", testCreatingFileWithString),
        ("testUsingCustomFileManager", testUsingCustomFileManager),
        ("testFolderContainsFile", testFolderContainsFile),
        ("testFolderContainsSubfolder", testFolderContainsSubfolder),
        ("testErrorDescriptions", testErrorDescriptions)
    ]
}

#if os(macOS)
extension FilesTests {
    @Test func testAccessingDocumentsFolder() throws {
        #expect(nil != Folder.documents, "Documents folder should be available.")
    }
}
#endif

#if os(iOS) || os(tvOS) || os(macOS)
extension FilesTests {
    @Test func testAccessingLibraryFolder() throws {
        #expect(nil != Folder.library, "Library folder should be available.")
    }

    @Test func testResolvingFolderMatchingSearchPath() throws {
        try performTest {
            // Real file I/O
            #expect(try Folder.matching(.cachesDirectory) != nil)
            #expect(try Folder.matching(.libraryDirectory) != nil)

            // Mocked file I/O
            final class FileManagerMock: FileManager {
                var target: Folder?

                override func urls(
                    for directory: FileManager.SearchPathDirectory,
                    in domainMask: FileManager.SearchPathDomainMask
                ) -> [URL] {
                    return target.map { [$0.url] } ?? []
                }
            }

            let target = try folder.createSubfolder(named: "Target")

            let fileManager = FileManagerMock()
            fileManager.target = target

            let resolved = try Folder.matching(.documentDirectory,
                resolvedBy: fileManager
            )

            #expect(resolved ==  target)
        }
    }
}
#endif
