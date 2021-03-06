//
//  SpawnPoint.swift
//  RealDeviceMap
//
//  Created by Florian Kostenzer on 06.10.18.
//

import Foundation
import PerfectLib
import PerfectMySQL
import POGOProtos

class SpawnPoint: JSONConvertibleObject{
    
    class ParsingError: Error {}
    
    override func getJSONValues() -> [String : Any] {
        return [
            "id":id,
            "lat":lat,
            "lon":lon,
            "updated":updated
        ]
    }
    
    var id: UInt64
    var lat: Double
    var lon: Double
    var updated: UInt32
    
    
    init(id: UInt64, lat: Double, lon: Double, updated: UInt32) {
        self.id = id
        self.lat = lat
        self.lon = lon
        self.updated = updated
    }

    public func save() throws {
        
        guard let mysql = DBController.global.mysql else {
            Log.error(message: "[SPAWNPOINT] Failed to connect to database.")
            throw DBController.DBError()
        }
        
        let oldSpawnpoint: SpawnPoint?
        do {
            oldSpawnpoint = try SpawnPoint.getWithId(id: id)
        } catch {
            oldSpawnpoint = nil
        }
        let mysqlStmt = MySQLStmt(mysql)
        
        if oldSpawnpoint == nil {

            let sql = """
                INSERT INTO spawnpoint (id, lat, lon, updated)
                VALUES (?, ?, ?, ?)
            """
            _ = mysqlStmt.prepare(statement: sql)
            mysqlStmt.bindParam(id)
            mysqlStmt.bindParam(lat)
            mysqlStmt.bindParam(lon)
            mysqlStmt.bindParam(updated)
            
            guard mysqlStmt.execute() else {
                Log.error(message: "[SPAWNPOINT] Failed to execute query. (\(mysqlStmt.errorMessage())")
                throw DBController.DBError()
            }
        }

    }
    
    public static func getAll(minLat: Double, maxLat: Double, minLon: Double, maxLon: Double, updated: UInt32) throws -> [SpawnPoint] {
        
        guard let mysql = DBController.global.mysql else {
            Log.error(message: "[SPAWNPOINT] Failed to connect to database.")
            throw DBController.DBError()
        }
        
        let sql = """
            SELECT id, lat, lon, updated
            FROM spawnpoint
            WHERE lat >= ? AND lat <= ? AND lon >= ? AND lon <= ? AND updated > ?
        """
        
        let mysqlStmt = MySQLStmt(mysql)
        _ = mysqlStmt.prepare(statement: sql)
        mysqlStmt.bindParam(minLat)
        mysqlStmt.bindParam(maxLat)
        mysqlStmt.bindParam(minLon)
        mysqlStmt.bindParam(maxLon)
        mysqlStmt.bindParam(updated)
        
        guard mysqlStmt.execute() else {
            Log.error(message: "[SPAWNPOINT] Failed to execute query. (\(mysqlStmt.errorMessage())")
            throw DBController.DBError()
        }
        let results = mysqlStmt.results()
        
        var spawnpoints = [SpawnPoint]()
        while let result = results.next() {
            
            let id = result[0] as! UInt64
            let lat = result[1] as! Double
            let lon = result[2] as! Double
            let updated = result[3] as! UInt32
            
            spawnpoints.append(SpawnPoint(id: id, lat: lat, lon: lon, updated: updated))
            
        }
        return spawnpoints
        
    }
    
    public static func getWithId(id: UInt64) throws -> SpawnPoint? {
        
        guard let mysql = DBController.global.mysql else {
            Log.error(message: "[SPAWNPOINT] Failed to connect to database.")
            throw DBController.DBError()
        }
        
        let sql = """
            SELECT id, lat, lon, updated
            FROM spawnpoint
            WHERE id = ?
        """
        
        let mysqlStmt = MySQLStmt(mysql)
        _ = mysqlStmt.prepare(statement: sql)
        mysqlStmt.bindParam(id)

        guard mysqlStmt.execute() else {
            Log.error(message: "[SPAWNPOINT] Failed to execute query. (\(mysqlStmt.errorMessage())")
            throw DBController.DBError()
        }
        let results = mysqlStmt.results()
        if results.numRows == 0 {
            return nil
        }
        
        let result = results.next()!
        
        let id = result[0] as! UInt64
        let lat = result[1] as! Double
        let lon = result[2] as! Double
        let updated = result[3] as! UInt32
        
        return SpawnPoint(id: id, lat: lat, lon: lon, updated: updated)
        
    }
    
}
