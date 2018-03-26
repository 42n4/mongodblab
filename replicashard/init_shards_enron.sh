./init_clean.sh
./init_clean.sh
mongod -f mongodb_shard_z1.conf
mongod -f mongodb_shard_z2.conf
mongod -f mongodb_shard_z3.conf

mongo --port 27101 --eval "rs.initiate( {
   _id : 'z',
   members: [
      { _id: 0, host: 'gen2db:27101' },
      { _id: 1, host: 'gen2db:27102' },
      { _id: 2, host: 'gen2db:27103' }
   ]
});
rs.status();"
sleep 15
mongo --port 27101 --eval "cfg=rs.conf();
cfg.members[0].priority=1;
cfg.members[1].priority=0.8;
cfg.members[2].priority=0.6;
rs.reconfig(cfg);"
sleep 5
mongo --port 27101 --eval "rs.status();"
mongorestore --host z/gen2db:27101,gen2db:27102,gen2db:27103 --drop --db enron ../dump/enron
#mongoimport --host z/gen2db:27101,gen2db:27102,gen2db:27103 -d mydb -c zips < ../zips.json
mongo --host z/gen2db:27101,gen2db:27102,gen2db:27103  mydb --eval "db.messages.count()"
mongo --port 27101  mydb --eval "db.messages.count()"

mongod -f mongodb_shard1_z1.conf
mongod -f mongodb_shard1_z2.conf
mongod -f mongodb_shard1_z3.conf

mongo --port 27401 --eval "rs.initiate( {
   _id : 'z1',
   members: [
      { _id: 0, host: 'gen2db:27401' },
      { _id: 1, host: 'gen2db:27402' },
      { _id: 2, host: 'gen2db:27403' }
   ]
});
rs.status();"
sleep 15
mongo --port 27401 --eval "rs.status();"
mongo --port 27401 --eval "cfg=rs.conf();
cfg.members[0].priority=1;
cfg.members[1].priority=0.8;
cfg.members[2].priority=0.6;
rs.reconfig(cfg);"
sleep 5

mongod -f mongodb_config_z1.conf
mongod -f mongodb_config_z2.conf
mongod -f mongodb_config_z3.conf

mongo --port 27201 --eval "rs.initiate( {
   _id : 'zconf',
   members: [
      { _id: 0, host: 'gen2db:27201' },
      { _id: 1, host: 'gen2db:27202' },
      { _id: 2, host: 'gen2db:27203' }
   ]
});
rs.status();"
sleep 15
mongo --port 27201 --eval "rs.status();"
mongo --port 27201 --eval "cfg=rs.conf();
cfg.members[0].priority=1;
cfg.members[1].priority=0.8;
cfg.members[2].priority=0.6;
rs.reconfig(cfg);"
sleep 5

mongos -f mongos_z1.conf
mongos -f mongos_z2.conf
mongos -f mongos_z3.conf

sleep 5
mongo --port 27001 --eval "sh.status()
sh.addShard('z/gen2db:27101,gen2db:27102,gen2db:27103')
sh.addShard('z1/gen2db:27401,gen2db:27402,gen2db:27403')
sh.enableSharding('enron')"

mongo enron --port 27001 --eval "db.messages.ensureIndex({'_id':'hashed'})
sh.shardCollection('enron.messages', {'_id':'hashed'})"

mongo --port 27001 --eval "sh.setBalancerState(true);
sh.isBalancerRunning()
sh.getBalancerState()"

sleep 1
mongo enron --port 27001 --eval "sh.status()"
echo 'mongo mydb --port 27001 --eval "sh.status()"'

mongo config --port 27001 --eval "db.locks.find( { '_id' : 'balancer' } ).pretty()"
#mongo mydb --port 27001 --eval "db.settings.update( { '_id': 'balancer' }, { $set: { activeWindow : { start: '15:00', stop: '6:00' } } }, { upsert: true })"
#db.settings.update(    { '_id': 'chunksize' },    { $set: { value : 1 } },    { upsert: true } )



