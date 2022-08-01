//
//  Stream.swift
//  Whisper
//
//  Created by Yang Tao on 2022/07/27.
//

import Foundation
import CryptoKit

// MARK: -
// 现 Golang 程序员写 Swift 中。
protocol Reader {
	// 读取至多 upToCount 字节。
	// 读取的字节数可能少于要求的，方便在代码中处理字节数不足时的情况。
	func read(upToCount count: Int) throws -> Data
}
protocol Writer {
	func write(_ data: Data) throws
}

// MARK: -

extension Reader {
	func read(count: Int) throws -> Data {
		let d = try read(upToCount: count)
		if d.count != count {
			throw "premature eof of data"
		}
		return d
	}
	func readUInt32() throws -> UInt32 {
		let d = try read(count: 4)
		return try UInt32.fromLittleEndian(d)
	}
	func readStringWithLength() throws -> String {
		let length = try readUInt32()
		let bytes = try read(count: Int(length))
		guard let s = String(data: bytes, encoding: .utf8) else {
			throw "invalid string encoding"
		}
		return s
	}
	func readDataWithLength() throws -> Data {
		let length = try readUInt32()
		let bytes = try read(count: Int(length))
		return bytes
	}
	func readFileWithLength(toDir: URL) throws -> URL {
		let fileName = try readStringWithLength()
		let fileSize = try readUInt32()
		
		let fileURL = toDir.appendingPathComponent(fileName)
		if !FileManager.default.createFile(atPath: fileURL.path, contents: nil) {
			throw "未能创建文件"
		}
		let handle = try FileHandle(forWritingTo: fileURL)
		
		let kBlockSize = 1 << 20
		var remaining = Int(fileSize)
		
		do {
			while remaining > 0 {
				let bytesToRead = min(remaining, kBlockSize)
				let d = try read(count: bytesToRead)
				try handle.write(contentsOf: d)
				remaining -= bytesToRead
			}
		} catch {
			try handle.close()
			throw error
		}
		
		try handle.close()
		
		return fileURL
	}
}
extension Writer {
	func write(_ n: UInt32) throws {
		try write(n.toLittleEndian())
	}
	func write(_ n: Int) throws {
		if n < 0 || n > UInt32.max {
			throw "invalid integer to uint32"
		}
		try write(UInt32(n))
	}
	func write(_ str: String, withLength: Bool) throws {
		let d = Data(str.utf8)
		if withLength {
			try write(d.count)
		}
		try write(d)
	}
	func write(_ data: Data, withLength: Bool) throws {
		try write(data.count)
		try write(data)
	}
	func write(_ handle: FileHandle, maxBytes: Int, withLength: Bool) throws {
		if withLength {
			try write(maxBytes)
		}
		
		let kBlockSize = 1 << 20
		var remaining = maxBytes
		
		while remaining > 0 {
			let bytesToRead = min(remaining, kBlockSize)
			let subData = try handle.read(upToCount: bytesToRead)
			if subData == nil {
				throw "内部错误：FileHandle 返回了 nil Data"
			}
			if subData!.count <= 0 {
				break
			}
			try write(subData!)
			remaining -= bytesToRead
		}
	}
}


// MARK: -

class MemoryWriter: Writer {
	private var buf = Data()
	
	func write<T>(_ data: T) throws where T : DataProtocol {
		buf.append(contentsOf: data)
	}
	
	func bytes() -> Data {
		return buf
	}
}

class MemoryReader: Reader {
	private var data: Data
	
	init(data: Data) {
		self.data = data
	}
	
	func read(upToCount count: Int) throws -> Data {
		let nBytes = min(data.count, count)
		let sub = data[0..<nBytes]
		self.data = data.advanced(by: nBytes)
		return sub
	}
}

// MARK: -

class FileReader: Reader {
	private var h: FileHandle
	
	init(_ url: URL) throws {
		self.h = try FileHandle(forReadingFrom: url)
	}
	
	func close() throws {
		try h.close()
	}
	
	func read(upToCount count: Int) throws -> Data {
		let d = try h.read(upToCount: count)
		if d == nil {
			throw "内部错误：FileHandle.read -> nil"
		}
		return d!
	}
}

class FileWriter: Writer {
	private var h: FileHandle
	private var url: URL
	
	init(_ url: URL) throws {
		self.url = url
		FileManager.default.createFile(atPath: url.path, contents: nil)
		self.h = try FileHandle(forWritingTo: url)
	}
	
	func URL() -> URL {
		return url
	}
	
	func close() throws {
		try h.close()
	}
	
	func write<T>(_ data: T) throws where T : DataProtocol {
		try h.write(contentsOf: data)
	}
}

// MARK: -

// 对称加密🔐时，加密块的大小
fileprivate let kChunkSize = 64 << 10

// 一个流数据分块加密类。
class StreamWriter: Writer {
	private var w: Writer
	private var buf: Data
	private var block: BlockEncryptor
	
	init(_ w: Writer, block: BlockEncryptor) {
		self.w = w
		self.block = block
		
		if kChunkSize <= 0 {
			fatalError("内部错误：无效块大小")
		}
		self.buf = Data(capacity: kChunkSize)
	}
	
	func close() throws {
		try writeChunks(last: true)
		try writeChunkEnd()
	}
	
	func write(_ data: Data) throws {
		buf.append(data)
		try writeChunks(last: false)
	}
	
	// 首先整块整块地写，如果 last = true，不为整块的也会写。
	private func writeChunks(last: Bool) throws {
		while buf.count >= kChunkSize {
			try _writeChunk()
		}
		
		if last && buf.count > 0 {
			try _writeChunk()
		}
	}
	
	// 从 buf 里面取出一块，写一块数据。
	// 只能在 buf > 0 的时候调用。
	private func _writeChunk() throws {
		if buf.count <= 0 {
			throw "trying to write zero byte chunk"
		}
		
		let maxBytes = min(kChunkSize, buf.count)
		let subBuf = buf[0..<maxBytes]
		let encrypted = try block.Encrypt(subBuf)
		try w.write(encrypted, withLength: true)
		buf = buf.advanced(by: maxBytes)
	}
	
	// 写块结束，以 0 长度为标识。
	private func writeChunkEnd() throws {
		if buf.count > 0 {
			throw "unchunked data present, cannot write chunk end"
		}
		
		try w.write(buf.count)
	}
}

// MARK: - asdf

class StreamReader: Reader {
	private var r: Reader
	private var eof: Bool
	private var buf: Data
	private var block: BlockDecryptor
	
	init(_ r: Reader, block: BlockDecryptor) {
		self.r = r
		self.block = block
		
		self.buf = Data()
		self.eof = false
	}
	
	func read(upToCount count: Int) throws -> Data {
		try ensureBuf(count)
		let maxBytes = min(count, buf.count)
		let subData = buf[0..<maxBytes]
		buf = buf.advanced(by: maxBytes)
		return subData
	}
	
	func close() throws {
		try readChunk()
		if buf.count > 0 || !eof {
			throw "stream has extra data"
		}
	}
	
	private func ensureBuf(_ n: Int) throws {
		while buf.count < n && !eof {
			try readChunk()
		}
	}
	
	private func readChunk() throws {
		if eof {
			throw "already reached end of chunk, cannot read more chunks"
		}
		
		let nd = try r.read(upToCount: 4)
		if nd.count != 4 {
			throw "corrupted chunk header"
		}
		let n = try UInt32.fromLittleEndian(nd)
		if n == 0 {
			eof = true
			return
		}
		let cd = try r.read(upToCount: Int(n))
		if cd.count != Int(n) {
			throw "corrupted chunk data"
		}
		
		let decrypted = try block.Decrypt(cd)
		buf.append(decrypted)
	}
}

// MARK: -

extension UInt32 {
	static func fromLittleEndian(_ data: Data) throws -> Self {
		if data.count != 4 {
			throw "invalid uint32 little endian data"
		}
		return withUnsafeBytes(of: data) { $0.load(as: UInt32.self) }.littleEndian
	}
	
	func toLittleEndian() -> Data {
		return withUnsafeBytes(of: self.littleEndian){ Data($0) }
	}
}
